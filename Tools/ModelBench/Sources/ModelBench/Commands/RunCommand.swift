//
//  RunCommand.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import ArgumentParser
import Foundation
import ModelManager

/// Benchmarks downloaded models against the fixture corpus.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct Run: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run the benchmark suite against one or more downloaded models."
    )

    @Option(name: .long, help: "Model identifiers to benchmark. Defaults to every downloaded model.")
    var model: [String] = []

    @Option(name: .long, help: "Path to a suite JSON file. Defaults to the bundled suite.")
    var suite: String?

    @Option(name: .long, help: "Path to a corpus directory. Defaults to the bundled corpus.")
    var corpus: String?

    @Option(name: .long, help: "Directory to write results into.")
    var output: String = "bench-results"

    @Option(name: .long, help: "How many times to run each task. Overrides the suite value.")
    var repeats: Int?

    @Flag(name: .long, help: "Print each answer as it is produced.")
    var verbose = false

    func run() async throws {
        let suiteURL = try suite.map { URL(fileURLWithPath: $0) } ?? Resources.suite()
        let corpusURL = try corpus.map { URL(fileURLWithPath: $0) } ?? Resources.corpus()
        var loadedSuite = try BenchSuite.load(from: suiteURL)

        if let repeats {
            loadedSuite.repeats = repeats
        }

        let available = try LocalModelRepo.shared.availableModels()
        let selected: [DownloadedModel]

        if model.isEmpty {
            selected = available
        } else {
            selected = try model.map { id in
                guard let match = available.first(where: { $0.id == id }) else {
                    throw BenchError.modelNotFound(id)
                }
                return match
            }
        }

        guard !selected.isEmpty else { throw BenchError.noModelsSelected }

        print("Building corpus…")
        let location = FileManager.default.temporaryDirectory.appending(path: "modelbench-corpus-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: location) }

        let builtCorpus = try await BenchCorpus.build(from: corpusURL, at: location)
        print("  \(builtCorpus.documents.count) documents, \(builtCorpus.documents.reduce(0) { $0 + $1.excerpts.count }) excerpts")

        let runner = BenchRunner(corpus: builtCorpus, suite: loadedSuite)
        var results: [ModelResult] = []

        let outputDirectory = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let startedAt = Date()
        let stamp = ISO8601DateFormatter.filenameSafe.string(from: startedAt)
        let jsonURL = outputDirectory.appending(path: "run-\(stamp).json")
        let markdownURL = outputDirectory.appending(path: "run-\(stamp).md")
        let taskCSVURL = outputDirectory.appending(path: "run-\(stamp)-tasks.csv")
        let checkCSVURL = outputDirectory.appending(path: "run-\(stamp)-checks.csv")

        /// Writes everything gathered so far. Called after each task so an interrupted run —
        /// a sweep of ten models takes hours — still leaves usable results on disk.
        let writeArtifacts: @Sendable (BenchReport) throws -> Void = { report in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            try encoder.encode(report).write(to: jsonURL)
            try Data(report.markdown().utf8).write(to: markdownURL)
            try Data(report.taskCSV().utf8).write(to: taskCSVURL)
            try Data(report.checkCSV().utf8).write(to: checkCSVURL)
        }

        for model in selected {
            // Immutable snapshot: the progress closure is @Sendable and cannot capture the
            // mutable accumulator.
            let completed = results

            print("")
            print("▶ \(model.id)")

            let result = await runner.run(model: model) { task, partial in
                let status = task.failure == nil ? "" : "  ⚠︎ \(task.failure ?? "")"
                print(
                    "  \(task.taskID.padding(toLength: 22, withPad: " ", startingAt: 0))"
                        + " #\(task.attempt + 1)"
                        + " prompt \("\(task.promptPassed)/\(task.promptTotal)".leftPadded(to: 6))"
                        + " (\(task.promptScore.percent.leftPadded(to: 4)))"
                        + "  tools \("\(task.toolPassed)/\(task.toolTotal)".leftPadded(to: 6))"
                        + " (\(task.toolScore.percent.leftPadded(to: 4)))"
                        + "  \(String(format: "%5.1f", task.tokensPerSecond)) tok/s"
                        + "  \(task.toolCallCount) calls"
                        + status
                )

                if verbose {
                    print("    → \(task.answer.replacingOccurrences(of: "\n", with: "\n      "))")
                }

                // Flush after every task. A sweep runs for hours, so an interruption must not
                // discard everything measured so far.
                try? writeArtifacts(BenchReport(generatedAt: startedAt, models: completed + [partial]))
            }

            if let failure = result.loadFailure {
                print("  failed to load: \(failure)")
            } else {
                print("  overall \(result.overallScore.percent)")
            }

            results.append(result)
            try writeArtifacts(BenchReport(generatedAt: startedAt, models: results))
        }

        let report = BenchReport(generatedAt: startedAt, models: results)
        try writeArtifacts(report)

        print("")
        print(report.markdown())
        print("")
        print("Wrote \(jsonURL.path(percentEncoded: false))")
        print("Wrote \(markdownURL.path(percentEncoded: false))")
        print("Wrote \(taskCSVURL.path(percentEncoded: false))    one row per task attempt")
        print("Wrote \(checkCSVURL.path(percentEncoded: false))   one row per check")
    }
}

extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }
}

extension ISO8601DateFormatter {
    /// An ISO-8601 formatter whose output is safe to use inside a filename.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static var filenameSafe: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime]
        return formatter
    }
}

/// Locates the bundled corpus and suite, whether running from `swift run` or an installed binary.
///
/// - Authored by: Claude Opus 5 (Anthropic)
enum Resources {
    static func corpus() throws -> URL {
        guard let url = Bundle.module.url(forResource: "corpus", withExtension: nil) else {
            throw BenchError.missingResource("corpus")
        }
        return url
    }

    static func suite() throws -> URL {
        guard let url = Bundle.module.url(forResource: "suite", withExtension: "json") else {
            throw BenchError.missingResource("suite.json")
        }
        return url
    }
}
