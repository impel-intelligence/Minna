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
    var power: PowerUsage = .unavailable

    var promptScore: Double { promptChecks.score }
    var toolScore: Double { toolChecks.score }

    /// The checks that failed, for the "what went wrong" section of the report.
    var failedChecks: [Check] { (promptChecks + toolChecks).filter { !$0.passed } }

    // MARK: - Raw counts
    //
    // The percentage scores are weighted ratios, which makes them hard to reason about on their
    // own. These are the underlying counts, reported alongside every score.

    var promptPassed: Int { promptChecks.count(where: \.passed) }
    var promptTotal: Int { promptChecks.count }
    var toolPassed: Int { toolChecks.count(where: \.passed) }
    var toolTotal: Int { toolChecks.count }

    var toolCallCount: Int { invocations.count }
    var searchCount: Int { invocations.count { ToolGrader.searchToolNames.contains($0.toolName) } }
    var citationCount: Int { PromptGrader.citations(in: answer).count }
    var answerCharacters: Int { answer.count }
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

    // MARK: - Raw totals

    var promptPassed: Int { tasks.reduce(0) { $0 + $1.promptPassed } }
    var promptTotal: Int { tasks.reduce(0) { $0 + $1.promptTotal } }
    var toolPassed: Int { tasks.reduce(0) { $0 + $1.toolPassed } }
    var toolTotal: Int { tasks.reduce(0) { $0 + $1.toolTotal } }
    var attemptCount: Int { tasks.count }
    var timedOutCount: Int { tasks.count { ($0.failure?.contains("timed out")) == true } }
    var erroredCount: Int { tasks.count { $0.failure != nil } }
    var totalSeconds: Double { tasks.reduce(0) { $0 + $1.totalSeconds } }

    /// True when any attempt ran on wall power, which invalidates the battery figures.
    var anyOnACPower: Bool { tasks.contains { $0.power.onACPower } }
    var batteryMeasured: Bool { !anyOnACPower && tasks.contains { $0.power.sampleCount > 0 } }

    /// Total battery percentage consumed across the whole model run, fractional.
    var batteryPercentageDrop: Double { tasks.reduce(0) { $0 + $1.power.percentageDrop } }
    var batteryMilliampHours: Double { tasks.reduce(0) { $0 + $1.power.milliampHours } }
    var energyWattHours: Double { tasks.reduce(0) { $0 + $1.power.wattHours } }
    var medianWatts: Double { tasks.map(\.power.averageWatts).filter { $0 > 0 }.median }

    /// On-die power, which unlike the battery figures is available on a desktop and on wall power.
    var packageMeasured: Bool { tasks.contains { $0.power.packageMeasured } }
    var medianPackageWatts: Double { tasks.map(\.power.packageWatts).filter { $0 > 0 }.median }
    var medianCPUWatts: Double { tasks.map(\.power.cpuWatts).filter { $0 > 0 }.median }
    var medianGPUWatts: Double { tasks.map(\.power.gpuWatts).filter { $0 > 0 }.median }
    var packageWattHours: Double { tasks.reduce(0) { $0 + $1.power.packageWattHours } }

    /// Energy cost per 1000 generated tokens from the on-die counters — the desktop-safe
    /// equivalent of `wattHoursPerThousandTokens`.
    var packageWattHoursPerThousandTokens: Double {
        let tokens = tasks.reduce(0) { $0 + $1.outputTokens }
        guard tokens > 0 else { return 0 }
        return packageWattHours / Double(tokens) * 1000
    }

    /// Energy cost per 1000 generated tokens — the figure that actually compares models,
    /// since a faster model finishing sooner can draw more watts and still cost less.
    var wattHoursPerThousandTokens: Double {
        let tokens = tasks.reduce(0) { $0 + $1.outputTokens }
        guard tokens > 0 else { return 0 }
        return energyWattHours / Double(tokens) * 1000
    }

    /// Every distinct check, with how often it passed across the whole model run.
    ///
    /// This is the most directly useful view: a check failing 36/36 is a systematic weakness,
    /// one failing 4/36 is sampling noise.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var checkTally: [(name: String, axis: String, passed: Int, total: Int)] {
        var order: [String] = []
        var axes: [String: String] = [:]
        var passed: [String: Int] = [:]
        var total: [String: Int] = [:]

        for task in tasks {
            for (axis, checks) in [("prompt", task.promptChecks), ("tools", task.toolChecks)] {
                for check in checks {
                    if total[check.name] == nil {
                        order.append(check.name)
                        axes[check.name] = axis
                    }
                    total[check.name, default: 0] += 1
                    passed[check.name, default: 0] += check.passed ? 1 : 0
                }
            }
        }

        return order.map { ($0, axes[$0] ?? "", passed[$0] ?? 0, total[$0] ?? 0) }
    }

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

    /// One row per task attempt, with every raw measurement taken.
    ///
    /// Emitted so scores can be recomputed, reweighted, or ignored entirely — the percentages
    /// are a summary, not the data.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    func taskCSV() -> String {
        var rows = [
            [
                "model", "task", "kind", "attempt",
                "prompt_checks_passed", "prompt_checks_total", "prompt_score",
                "tool_checks_passed", "tool_checks_total", "tool_score",
                "tool_calls", "searches", "citations",
                "output_tokens", "answer_chars",
                "ttft_seconds", "total_seconds", "tokens_per_second",
                "peak_memory_bytes", "model_bytes",
                "avg_watts", "watt_hours", "watt_hours_per_minute",
                "battery_percent_drop", "battery_mah", "power_samples", "on_ac_power",
                "package_watts", "cpu_watts", "gpu_watts", "ane_watts", "dram_watts",
                "package_watt_hours",
                "cpu_energy_raw", "cpu_energy_unit",
                "gpu_energy_raw", "gpu_energy_unit",
                "ane_energy_raw", "ane_energy_unit",
                "dram_energy_raw", "dram_energy_unit",
                "failure"
            ].joined(separator: ",")
        ]

        for model in models {
            for task in model.tasks {
                // Built in stages: one expression this wide defeats the type checker.
                let identity: [String] = [
                    model.modelID.csvEscaped,
                    task.taskID.csvEscaped,
                    task.kind.rawValue,
                    String(task.attempt + 1)
                ]

                let grading: [String] = [
                    String(task.promptPassed), String(task.promptTotal), String(format: "%.4f", task.promptScore),
                    String(task.toolPassed), String(task.toolTotal), String(format: "%.4f", task.toolScore),
                    String(task.toolCallCount), String(task.searchCount), String(task.citationCount)
                ]

                let timings: [String] = [
                    String(task.outputTokens), String(task.answerCharacters),
                    String(format: "%.3f", task.timeToFirstToken),
                    String(format: "%.3f", task.totalSeconds),
                    String(format: "%.2f", task.tokensPerSecond),
                    String(task.peakMemoryBytes), String(model.sizeBytes)
                ]

                let battery: [String] = [
                    String(format: "%.3f", task.power.averageWatts),
                    String(format: "%.5f", task.power.wattHours),
                    String(format: "%.5f", task.power.wattHoursPerMinute),
                    String(format: "%.4f", task.power.percentageDrop),
                    String(format: "%.1f", task.power.milliampHours),
                    String(task.power.sampleCount),
                    task.power.onACPower ? "1" : "0"
                ]

                let onDie: [String] = [
                    String(format: "%.3f", task.power.packageWatts),
                    String(format: "%.3f", task.power.cpuWatts),
                    String(format: "%.3f", task.power.gpuWatts),
                    String(format: "%.3f", task.power.aneWatts),
                    String(format: "%.3f", task.power.dramWatts),
                    String(format: "%.5f", task.power.packageWattHours)
                ]

                // Raw counter deltas in the units IOReport reported them in, so nothing is lost
                // to the watt conversion.
                let counters: [String] = [
                    String(task.power.cpuEnergy.rawValue), task.power.cpuEnergy.unit,
                    String(task.power.gpuEnergy.rawValue), task.power.gpuEnergy.unit,
                    String(task.power.aneEnergy.rawValue), task.power.aneEnergy.unit,
                    String(task.power.dramEnergy.rawValue), task.power.dramEnergy.unit
                ]

                let fields = identity + grading + timings + battery + onDie + counters + [(task.failure ?? "").csvEscaped]
                rows.append(fields.joined(separator: ","))
            }
        }

        return rows.joined(separator: "\n") + "\n"
    }

    /// One row per individual check per attempt — the rawest form of the grading.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    func checkCSV() -> String {
        var rows = ["model,task,attempt,axis,check,passed,weight,detail"]

        for model in models {
            for task in model.tasks {
                for (axis, checks) in [("prompt", task.promptChecks), ("tools", task.toolChecks)] {
                    for check in checks {
                        rows.append(
                            [
                                model.modelID.csvEscaped,
                                task.taskID.csvEscaped,
                                String(task.attempt + 1),
                                axis,
                                check.name.csvEscaped,
                                check.passed ? "1" : "0",
                                String(format: "%.1f", check.weight),
                                (check.detail ?? "").csvEscaped
                            ].joined(separator: ",")
                        )
                    }
                }
            }
        }

        return rows.joined(separator: "\n") + "\n"
    }

    /// Renders the leaderboard and per-model detail as markdown.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    func markdown() -> String {
        var lines: [String] = []

        lines.append("# ModelBench results")
        lines.append("")
        lines.append("Generated \(ISO8601DateFormatter().string(from: generatedAt)).")
        lines.append("")
        lines.append("## Raw measurements")
        lines.append("")
        lines.append("Counts are checks passed across every task attempt. Timings are medians.")
        lines.append("")

        if models.contains(where: \.anyOnACPower) {
            lines.append("> The battery column is blank because the machine was on wall power. Package,")
            lines.append("> CPU and GPU watts come from the on-die counters and are unaffected — those work")
            lines.append("> on a desktop and while charging.")
            lines.append("")
        }
        lines.append("| Model | Prompt checks | Tool checks | tok/s | TTFT s | Load s | Peak RAM | On disk | Attempts | Errored | Wall clock | Pkg W | CPU W | GPU W | Pkg Wh | Wh/1k tok | Battery % |")
        lines.append("|-------|---------------|-------------|-------|--------|--------|----------|---------|----------|---------|------------|-------|-------|-------|--------|-----------|-----------|")

        for model in ranked {
            guard model.didLoad else {
                lines.append("| `\(model.modelID)` | failed to load | | | | | | \(model.sizeBytes.formattedBytes) | | | | | | | | | |")
                continue
            }

            lines.append(
                "| `\(model.modelID)` "
                    + "| \(model.promptPassed)/\(model.promptTotal) "
                    + "| \(model.toolPassed)/\(model.toolTotal) "
                    + "| \(String(format: "%.1f", model.medianTokensPerSecond)) "
                    + "| \(String(format: "%.1f", model.medianTimeToFirstToken)) "
                    + "| \(String(format: "%.1f", model.loadSeconds)) "
                    + "| \(model.peakMemoryBytes.formattedBytes) "
                    + "| \(model.sizeBytes.formattedBytes) "
                    + "| \(model.attemptCount) "
                    + "| \(model.erroredCount) "
                    + "| \(String(format: "%.0fs", model.totalSeconds)) "
                    + "| \(model.packageMeasured ? String(format: "%.1f", model.medianPackageWatts) : "—") "
                    + "| \(model.packageMeasured ? String(format: "%.1f", model.medianCPUWatts) : "—") "
                    + "| \(model.packageMeasured ? String(format: "%.1f", model.medianGPUWatts) : "—") "
                    + "| \(model.packageMeasured ? String(format: "%.2f", model.packageWattHours) : "—") "
                    + "| \(model.packageMeasured ? String(format: "%.3f", model.packageWattHoursPerThousandTokens) : "—") "
                    + "| \(model.batteryMeasured ? String(format: "%.2f%%", model.batteryPercentageDrop) : "—") |"
            )
        }

        lines.append("")
        lines.append("## Weighted scores")
        lines.append("")
        lines.append("Derived from the table above. See README for the weighting; prefer the raw numbers.")
        lines.append("")
        lines.append("| # | Model | Overall | Prompt | Tools | Speed | Size |")
        lines.append("|---|-------|---------|--------|-------|-------|------|")

        for (index, model) in ranked.enumerated() {
            guard model.didLoad else {
                lines.append("| \(index + 1) | `\(model.modelID)` | — | | | | |")
                continue
            }

            lines.append(
                "| \(index + 1) | `\(model.modelID)` "
                    + "| **\(model.overallScore.percent)** "
                    + "| \(model.promptScore.percent) "
                    + "| \(model.toolScore.percent) "
                    + "| \(model.speedScore.percent) "
                    + "| \(model.sizeScore.percent) |"
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
            lines.append("#### Checks, tallied across every attempt")
            lines.append("")
            lines.append("| Axis | Check | Passed |")
            lines.append("|------|-------|--------|")

            for entry in model.checkTally.sorted(by: { ($0.passed * $1.total) < ($1.passed * $0.total) }) {
                lines.append("| \(entry.axis) | \(entry.name) | \(entry.passed)/\(entry.total) |")
            }

            lines.append("")
            lines.append("#### Per task")
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

                let promptCounts = results.map { "\($0.promptPassed)/\($0.promptTotal)" }.joined(separator: " ")
                let toolCounts = results.map { "\($0.toolPassed)/\($0.toolTotal)" }.joined(separator: " ")

                lines.append(
                    "| \(taskID) "
                        + "| \(first.kind.rawValue) "
                        + "| \(promptCounts) "
                        + "| \(toolCounts) "
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

extension String {
    /// This string quoted for CSV when it contains a comma, quote, or newline.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var csvEscaped: String {
        guard contains(",") || contains("\"") || contains("\n") else { return self }
        return "\"\(replacingOccurrences(of: "\"", with: "\"\""))\""
    }
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
