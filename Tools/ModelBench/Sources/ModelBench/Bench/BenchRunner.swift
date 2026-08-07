//
//  BenchRunner.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import AnyLanguageModel
import Foundation
import IrisSearch
import MinnaChat
import ModelManager
import Tokenizers

/// Runs one model over a whole suite, one fresh session per task.
///
/// The session is built exactly the way `ChatInstance` builds it — same provider, same
/// `AskMinnaInstructions`, same tools, same `GenerationOptions` — so the harness measures the
/// configuration the app actually ships. It streams the response itself rather than calling
/// `ChatInstance.sendMessage` only because time-to-first-token has to be observed mid-stream.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct BenchRunner: Sendable {
    let corpus: BenchCorpus
    let suite: BenchSuite
    let tools: [AvailableTool]

    init(corpus: BenchCorpus, suite: BenchSuite, tools: [AvailableTool] = AvailableTool.allCases) {
        self.corpus = corpus
        self.suite = suite
        self.tools = tools
    }

    /// Benchmarks a single downloaded model across every task in the suite.
    ///
    /// - Parameters:
    ///   - model: The model to run.
    ///   - progress: Called as each task finishes, for console output.
    /// - Returns: The model's complete result, including per-task detail.
    /// - Authored by: Claude Opus 5 (Anthropic)
    func run(model: DownloadedModel, progress: @Sendable (TaskResult) -> Void) async -> ModelResult {
        let sizeBytes = (try? ByteCount.ofDirectory(model.directory)) ?? 0
        let tokenizer = try? await AutoTokenizer.from(modelFolder: model.directory)

        var provider: MLXProvider?
        var languageModel: (any LanguageModel)?
        var loadFailure: String?
        var loadSeconds: Double = 0

        do {
            let made = MLXProvider()
            let start = ContinuousClock.now
            let resolved = try made.getModel(id: model.id)

            // Pay the weight-loading cost once, up front, so it does not land inside the
            // first task's time-to-first-token.
            let warmup = LanguageModelSession(model: resolved, instructions: Instructions("You are a helpful assistant."))
            _ = try? await warmup.respond(to: Prompt("Say OK."), options: GenerationOptions(maximumResponseTokens: 4))

            loadSeconds = (ContinuousClock.now - start).seconds
            provider = made
            languageModel = resolved
        } catch {
            loadFailure = String(describing: error)
        }

        guard let provider, let languageModel else {
            return ModelResult(
                modelID: model.id,
                sizeBytes: sizeBytes,
                loadSeconds: loadSeconds,
                loadFailure: loadFailure,
                tasks: [],
                weights: suite.weights,
                budgets: suite.budgets
            )
        }

        var results: [TaskResult] = []

        for task in suite.tasks {
            for attempt in 0 ..< suite.repeatCount {
                var result = await run(
                    task: task,
                    model: model,
                    provider: provider,
                    languageModel: languageModel,
                    tokenizer: tokenizer
                )
                result.attempt = attempt
                results.append(result)
                progress(result)
            }
        }

        // Free the weights before the next model loads, or a multi-model run walks off the
        // end of unified memory.
        if let mlxModel = languageModel as? MLXLanguageModel {
            await mlxModel.removeFromCache()
        }

        return ModelResult(
            modelID: model.id,
            sizeBytes: sizeBytes,
            loadSeconds: loadSeconds,
            loadFailure: nil,
            tasks: results,
            weights: suite.weights,
            budgets: suite.budgets
        )
    }

    /// Runs one task in a fresh session, so tasks cannot contaminate each other.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    private func run(
        task: BenchTask,
        model: DownloadedModel,
        provider: MLXProvider,
        languageModel: any LanguageModel,
        tokenizer: Tokenizer?
    ) async -> TaskResult {
        let observer = BenchObserver()
        let memory = PeakMemoryRecorder()
        let power = PowerRecorder()

        // Mirrors ChatInstance.init: same instructions, same tools, same provider options.
        let session = LanguageModelSession(
            model: languageModel,
            tools: tools.map { $0.getTool(irisDB: corpus.database) },
            instructions: AskMinnaInstructions(maxSearches: suite.maximumSearches).getPrompt()
        )
        session.toolExecutionDelegate = observer

        await observer.beginTurn()
        await memory.start()
        await power.start()

        let options = provider.generationOptions(model: model)
        let start = ContinuousClock.now
        var firstTokenAt: Double?
        var answer = ""
        var failure: String?

        // A weak model can loop on tool calls indefinitely, emitting nothing. Race generation
        // against a deadline so one bad model cannot stall an overnight run, and keep whatever
        // partial answer arrived before the deadline.
        let progress = StreamProgress()

        let generation = Task {
            for try await snapshot in session.streamResponse(to: Prompt(task.prompt), options: options) {
                await progress.record(content: snapshot.content, at: (ContinuousClock.now - start).seconds)
            }
        }

        let timeout = Task {
            try await Task.sleep(for: .seconds(suite.taskTimeout))
            generation.cancel()
        }

        do {
            try await generation.value
            timeout.cancel()
        } catch is CancellationError {
            failure = "timed out after \(Int(suite.taskTimeout))s"
        } catch {
            timeout.cancel()
            failure = String(describing: error)
        }

        answer = await progress.content
        firstTokenAt = await progress.firstTokenAt

        let totalSeconds = (ContinuousClock.now - start).seconds
        let peakMemory = await memory.finish()
        let powerUsage = await power.finish()
        let invocations = await observer.recordedInvocations()

        let outputTokens = tokenizer.map { $0.encode(text: answer).count } ?? (answer.count / 4)

        // Decode time only — tool execution and prompt processing are excluded, so this is the
        // model's generation speed rather than end-to-end turn latency.
        let decodeSeconds = await progress.decodeSeconds
        let tokensPerSecond = decodeSeconds > 0 ? Double(outputTokens) / decodeSeconds : 0

        // AnyLanguageModel's MLX path stops after 8 tool iterations. Hitting it means the model
        // never converged on an answer.
        let hitToolLoopCap = invocations.count >= 8 && answer.isEmpty

        let promptChecks = PromptGrader.grade(
            answer: answer,
            task: task,
            corpus: corpus.documents,
            retrievedDocumentIDs: ToolGrader.retrievedDocumentIDs(from: invocations)
        )

        let toolChecks = ToolGrader.grade(
            invocations: invocations,
            task: task,
            maximumSearches: suite.maximumSearches,
            hitToolLoopCap: hitToolLoopCap,
            failure: failure
        )

        return TaskResult(
            taskID: task.id,
            kind: task.kind,
            prompt: task.prompt,
            answer: answer,
            failure: failure,
            invocations: invocations,
            promptChecks: promptChecks,
            toolChecks: toolChecks,
            timeToFirstToken: firstTokenAt ?? totalSeconds,
            totalSeconds: totalSeconds,
            outputTokens: outputTokens,
            tokensPerSecond: tokensPerSecond,
            peakMemoryBytes: peakMemory,
            power: powerUsage
        )
    }
}

/// Accumulates a streamed answer so a timed-out generation still yields whatever it produced,
/// and measures how long the model actually spent decoding.
///
/// Wall-clock time is a bad denominator for throughput here: a turn is mostly tool execution,
/// during which the model emits nothing. Dividing answer tokens by total elapsed time reports a
/// 3B model at 3 tok/s. This instead sums only the gaps between consecutive snapshots that grew
/// the answer, so the result is decode speed rather than a blend of decode and search latency.
///
/// - Authored by: Claude Opus 5 (Anthropic)
private actor StreamProgress {
    /// Gaps longer than this are a tool call or a prompt-processing pause, not decoding.
    private static let decodeGapCeiling: Double = 1.0

    private(set) var content: String = ""
    private(set) var firstTokenAt: Double?
    private(set) var decodeSeconds: Double = 0

    private var lastGrowthAt: Double?

    func record(content: String, at offset: Double) {
        defer { self.content = content }

        guard content.count > self.content.count else { return }

        if firstTokenAt == nil, !content.isEmpty {
            firstTokenAt = offset
        }

        if let lastGrowthAt {
            let gap = offset - lastGrowthAt
            if gap <= Self.decodeGapCeiling {
                decodeSeconds += gap
            }
        }

        lastGrowthAt = offset
    }
}
