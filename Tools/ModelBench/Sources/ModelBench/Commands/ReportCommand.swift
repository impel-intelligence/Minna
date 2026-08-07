//
//  ReportCommand.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import ArgumentParser
import Foundation

/// Re-renders a saved run as markdown, so scoring weights can be changed without re-running models.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct Report: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "report",
        abstract: "Render a saved benchmark run as markdown."
    )

    @Argument(help: "Path to a run JSON file produced by `modelbench run`.")
    var path: String

    func run() async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let report = try decoder.decode(BenchReport.self, from: data)

        print(report.markdown())
    }
}
