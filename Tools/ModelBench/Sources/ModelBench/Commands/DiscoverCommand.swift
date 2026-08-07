//
//  DiscoverCommand.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import ArgumentParser
import Foundation

/// Searches `mlx-community` for benchmark candidates and screens them for tool-calling support.
///
/// A small MLX model that ships a chat template with no `tools` handling cannot drive Minna's
/// tools at all, so screening the template up front avoids downloading gigabytes of dead weight.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct Discover: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "discover",
        abstract: "Find mlx-community models worth benchmarking."
    )

    @Option(name: .long, help: "Substring to search repository names for.")
    var search: String?

    @Option(name: .long, help: "Maximum number of repositories to screen.")
    var limit: Int = 60

    @Option(name: .long, help: "Skip repositories whose weights exceed this many gigabytes.")
    var maximumGigabytes: Double = 10

    @Flag(name: .long, help: "Include repositories whose chat template has no tool support.")
    var includeToolless = false

    func run() async throws {
        var components = URLComponents(string: "https://huggingface.co/api/models")!
        components.queryItems = [
            URLQueryItem(name: "author", value: "mlx-community"),
            URLQueryItem(name: "filter", value: "text-generation"),
            URLQueryItem(name: "sort", value: "downloads"),
            URLQueryItem(name: "direction", value: "-1"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let search {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let repositories = try JSONDecoder().decode([HubRepository].self, from: data)

        print("repository,gigabytes,toolSupport,downloads")

        for repository in repositories {
            guard !repository.id.lowercased().contains("base") else { continue }

            let bytes = await Self.weightBytes(of: repository.id)
            let gigabytes = Double(bytes) / 1_000_000_000

            guard gigabytes > 0, gigabytes <= maximumGigabytes else { continue }

            let support = await Self.toolSupport(of: repository.id)
            guard includeToolless || support == .supported else { continue }

            print("\(repository.id),\(String(format: "%.2f", gigabytes)),\(support.rawValue),\(repository.downloads ?? 0)")
        }
    }

    /// Whether a repository's chat template can express tool calls.
    enum ToolSupport: String {
        case supported
        case missing
        case unknown
    }

    /// Sums the repository's safetensors blobs to get a real download size.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func weightBytes(of repository: String) async -> Int64 {
        guard
            let url = URL(string: "https://huggingface.co/api/models/\(repository)?blobs=true"),
            let (data, _) = try? await URLSession.shared.data(from: url),
            let detail = try? JSONDecoder().decode(HubRepositoryDetail.self, from: data)
        else {
            return 0
        }

        return detail.siblings
            .filter { $0.rfilename.hasSuffix(".safetensors") }
            .reduce(0) { $0 + ($1.size ?? 0) }
    }

    /// Fetches the chat template — from `chat_template.jinja` or from `tokenizer_config.json` —
    /// and looks for tool-calling machinery.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func toolSupport(of repository: String) async -> ToolSupport {
        let candidates = [
            "https://huggingface.co/\(repository)/raw/main/chat_template.jinja",
            "https://huggingface.co/\(repository)/raw/main/tokenizer_config.json"
        ]

        for candidate in candidates {
            guard
                let url = URL(string: candidate),
                let (data, response) = try? await URLSession.shared.data(from: url),
                (response as? HTTPURLResponse)?.statusCode == 200,
                let text = String(data: data, encoding: .utf8)
            else {
                continue
            }

            guard text.contains("chat_template") || candidate.hasSuffix(".jinja") else { continue }

            let markers = ["tool_call", "tool_calls", "<tools>", "tools is defined", "for tool in tools"]
            return markers.contains(where: text.contains) ? .supported : .missing
        }

        return .unknown
    }
}

private struct HubRepository: Decodable {
    let id: String
    let downloads: Int?
}

private struct HubRepositoryDetail: Decodable {
    struct Sibling: Decodable {
        let rfilename: String
        let size: Int64?
    }

    let siblings: [Sibling]
}
