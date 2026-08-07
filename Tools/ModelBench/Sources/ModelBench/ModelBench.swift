//
//  ModelBench.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import ArgumentParser
import Darwin

/// A harness for comparing on-device MLX models against Minna's real chat stack.
///
/// Every model runs through the same `MLXProvider`, `AskMinnaInstructions` and tool set the app
/// uses, against a fixed corpus, so differences in score come from the model rather than from
/// retrieval noise or prompt drift.
///
/// - Authored by: Claude Opus 5 (Anthropic)
@main
struct ModelBench: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "modelbench",
        abstract: "Benchmark on-device MLX models against Minna's chat stack.",
        subcommands: [
            List.self,
            Fetch.self,
            Discover.self,
            Doctor.self,
            Run.self,
            Report.self
        ]
    )

    /// Benchmark runs are long and usually piped to a file, where fully buffered output would
    /// hide progress for minutes at a time.
    static func main() async {
        setvbuf(stdout, nil, _IOLBF, 0)

        do {
            var command = try parseAsRoot()

            if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
        } catch {
            exit(withError: error)
        }
    }
}
