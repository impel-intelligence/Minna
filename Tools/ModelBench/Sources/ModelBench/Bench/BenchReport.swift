//
//  BenchReport.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import Foundation

/// The graded outcome of one task on one model.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct TaskResult: Codable, Sendable {
    /// Which repeat of the task this is, zero-based.
    var attempt: Int = 0

    let taskID: String
    let kind: BenchTask.Kind
    let prompt: String
    let answer: String
    let failure: String?
    let invocations: [ToolInvocation]
    let promptChecks: [Check]
    let toolChecks: [Check]
    let timeToFirstToken: Double
    let totalSeconds: Double
    let outputTokens: Int
    let tokensPerSecond: Double
    let peakMemoryBytes: Int64

    var promptScore: Double { promptChecks.score }
    var toolScore: Double { toolChecks.score }

    /// The checks that failed, for the "what went wrong" section of the report.
    var failedChecks: [Check] { (promptChecks + toolChecks).filter { !$0.passed } }
}

/// Every task's outcome for one model, plus the aggregate scores.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct ModelResult: Codable, Sendable {
    let modelID: String
    let sizeBytes: Int64
    let loadSeconds: Double
    let loadFailure: String?
    let tasks: [TaskResult]
    let weights: BenchSuite.Weights
    let budgets: BenchSuite.Budgets

    var didLoad: Bool { loadFailure == nil }

    /// Task results grouped by task id, preserving suite order.
    var byTask: [(taskID: String, results: [TaskResult])] {
        var order: [String] = []
        var grouped: [String: [TaskResult]] = [:]

        for task in tasks {
            if grouped[task.taskID] == nil { order.append(task.taskID) }
            grouped[task.taskID, default: []].append(task)
        }

        return order.map { ($0, grouped[$0] ?? []) }
    }

    /// The median score for each task, averaged across tasks. Taking the median within a task
    /// first keeps one unlucky sample from dominating a model's rating.
    private func aggregate(_ score: (TaskResult) -> Double) -> Double {
        let perTask = byTask.map { $0.results.map(score).median }
        guard !perTask.isEmpty else { return 0 }
        return perTask.reduce(0, +) / Double(perTask.count)
    }

    var promptScore: Double { aggregate(\.promptScore) }
    var toolScore: Double { aggregate(\.toolScore) }

    var medianTokensPerSecond: Double { tasks.map(\.tokensPerSecond).median }
    var medianTimeToFirstToken: Double { tasks.map(\.timeToFirstToken).median }
    var peakMemoryBytes: Int64 { tasks.map(\.peakMemoryBytes).max() ?? 0 }

    var speedScore: Double {
        guard !tasks.isEmpty else { return 0 }
        return ResourceGrader.speedScore(
            tokensPerSecond: medianTokensPerSecond,
            timeToFirstToken: medianTimeToFirstToken,
            budgets: budgets
        )
    }

    var sizeScore: Double { ResourceGrader.sizeScore(bytes: sizeBytes, budgets: budgets) }

    /// The weighted composite the leaderboard sorts on.
    var overallScore: Double {
        guard didLoad, !tasks.isEmpty else { return 0 }
        let total = weights.prompt + weights.tools + weights.speed + weights.size
        guard total > 0 else { return 0 }
        return (promptScore * weights.prompt
            + toolScore * weights.tools
            + speedScore * weights.speed
            + sizeScore * weights.size) / total
    }
}

/// A whole benchmark run.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct BenchReport: Codable, Sendable {
    let generatedAt: Date
    let models: [ModelResult]

    var ranked: [ModelResult] { models.sorted { $0.overallScore > $1.overallScore } }

    /// Renders the leaderboard and per-model detail as markdown.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    func markdown() -> String {
        var lines: [String] = []

        lines.append("# ModelBench results")
        lines.append("")
        lines.append("Generated \(ISO8601DateFormatter().string(from: generatedAt)).")
        lines.append("")
        lines.append("| # | Model | Overall | Prompt | Tools | Speed | Size | tok/s | TTFT | Peak RAM | On disk |")
        lines.append("|---|-------|---------|--------|-------|-------|------|-------|------|----------|---------|")

        for (index, model) in ranked.enumerated() {
            guard model.didLoad else {
                lines.append("| \(index + 1) | `\(model.modelID)` | — | | | | | | | | failed to load |")
                continue
            }

            lines.append(
                "| \(index + 1) | `\(model.modelID)` "
                    + "| **\(model.overallScore.percent)** "
                    + "| \(model.promptScore.percent) "
                    + "| \(model.toolScore.percent) "
                    + "| \(model.speedScore.percent) "
                    + "| \(model.sizeScore.percent) "
                    + "| \(String(format: "%.1f", model.medianTokensPerSecond)) "
                    + "| \(String(format: "%.1fs", model.medianTimeToFirstToken)) "
                    + "| \(model.peakMemoryBytes.formattedBytes) "
                    + "| \(model.sizeBytes.formattedBytes) |"
            )
        }

        lines.append("")
        lines.append("## Per-model detail")

        for model in ranked {
            lines.append("")
            lines.append("### \(model.modelID)")
            lines.append("")

            if let failure = model.loadFailure {
                lines.append("Failed to load: `\(failure)`")
                continue
            }

            lines.append("Loaded in \(String(format: "%.1fs", model.loadSeconds)).")
            lines.append("")
            lines.append("| Task | Kind | Prompt | Tools | Spread | Tool calls | Most common failures |")
            lines.append("|------|------|--------|-------|--------|------------|----------------------|")

            for (taskID, results) in model.byTask {
                guard let first = results.first else { continue }

                let promptScores = results.map(\.promptScore)
                let spread = promptScores.isEmpty
                    ? "—"
                    : "\((promptScores.min() ?? 0).percent)–\((promptScores.max() ?? 0).percent)"

                // Rank failures by how often they recur across repeats: a check that fails every
                // time is a real weakness, one that fails once is sampling noise.
                var failureCounts: [String: Int] = [:]
                for result in results {
                    for check in result.failedChecks {
                        failureCounts[check.name, default: 0] += 1
                    }
                }

                let failures = failureCounts
                    .sorted { ($0.value, $1.key) > ($1.value, $0.key) }
                    .prefix(3)
                    .map { "\($0.key) (\($0.value)/\(results.count))" }
                    .joined(separator: "; ")

                let toolNames = results
                    .map { $0.invocations.map { $0.toolName }.joined(separator: ", ") }
                    .max(by: { $0.count < $1.count }) ?? ""

                lines.append(
                    "| \(taskID) "
                        + "| \(first.kind.rawValue) "
                        + "| \(promptScores.median.percent) "
                        + "| \(results.map(\.toolScore).median.percent) "
                        + "| \(spread) "
                        + "| \(toolNames.isEmpty ? "none" : toolNames) "
                        + "| \(failures.isEmpty ? "—" : failures) |"
                )
            }
        }

        return lines.joined(separator: "\n")
    }
}

extension Double {
    /// This 0–1 score rendered as a whole-number percentage.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var percent: String { String(format: "%.0f%%", self * 100) }
}

extension Array where Element == Double {
    /// The median, or zero for an empty array. Preferred over the mean so one stalled task
    /// does not dominate a model's reported throughput.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var median: Double {
        guard !isEmpty else { return 0 }
        let sorted = self.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
