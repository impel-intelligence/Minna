//
//  HuggingFaceDownloader.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/6/26.
//  Edited by Claude Opus 5 (Anthropic) on 2026-08-06: download once instead of twice,
//  land models in the shared model storage directory, and implement listModels().
//

import Foundation
import HuggingFace
import ModelCDN

/// Downloads MLX models from the Hugging Face Hub into Minna's shared model storage.
///
/// Models are materialized as a flat directory per model — the same layout
/// ``ModelCDNDownloader`` produces — so a Hub download and a CDN download are
/// indistinguishable to ``LocalModelRepo`` and to ``MLXProvider``.
///
/// - Authored by: Claude Opus 5 (Anthropic)
public final class HuggingFaceDownloader: Downloader, Sendable {
    public enum HuggingFaceError: Error, LocalizedError {
        case invalidRepositoryIdentifier(String)
        case invalidCache
        case noWeightsInRepository(String)
        case missingChatTemplate(String)

        public var errorDescription: String? {
            switch self {
            case .invalidRepositoryIdentifier(let id):
                return "\"\(id)\" is not a valid Hugging Face repository identifier. Expected the form \"namespace/name\"."
            case .invalidCache:
                return "Could not resolve the Hugging Face cache directory."
            case .noWeightsInRepository(let id):
                return "\"\(id)\" contains no .safetensors weights, so it is not a model Minna can run."
            case .missingChatTemplate(let id):
                return "\"\(id)\" has no chat template, so it cannot be used as a chat model."
            }
        }
    }

    /// Only the files an MLX chat model actually needs. Nothing here matches the
    /// original PyTorch weights, so we never pay to download a duplicate format.
    static let modelFilePatterns: [String] = ["*.safetensors", "*.safetensors.index.json", "*.json", "*.jinja"]

    let client: HubClient
    let cache: HubCache

    /// The directory each model is materialized into, one flat subdirectory per model.
    let storageDirectory: URL

    public init(cache: HubCache = .minnaCache, storageDirectory: URL = ManifestSharedSettings.modelStorageURL) {
        self.cache = cache
        self.client = HubClient(cache: cache)
        self.storageDirectory = storageDirectory
    }

    public func listModels() throws -> [DownloadedModel] {
        try DownloadedModel.models(in: storageDirectory)
    }

    /// Downloads `id` from the Hub and materializes it into the shared model storage directory.
    ///
    /// The stream yields download progress and finishes once the model is on disk and listable.
    /// Cancelling the stream cancels the download and removes partial state.
    ///
    /// - Parameter id: A Hub repository identifier such as `mlx-community/Nanbeige4.1-3B-8bit`.
    /// - Returns: A stream of ``Progress`` values covering the download.
    /// - Throws: ``HuggingFaceError/invalidRepositoryIdentifier(_:)`` when `id` is malformed.
    /// - Authored by: Claude Opus 5 (Anthropic)
    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
        guard let repoID = Repo.ID(rawValue: id) else {
            throw HuggingFaceError.invalidRepositoryIdentifier(id)
        }

        let client = client
        let cache = cache
        let destination = storageDirectory.appending(path: repoID.name, directoryHint: .isDirectory)

        return AsyncThrowingStream<Progress, Error>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task {
                do {
                    // Download into the Hub cache only. Handing `downloadSnapshot` a
                    // destination makes it copy every file out of the cache afterwards,
                    // which is what turned a 5 GB model into 10 GB on disk.
                    let snapshot = try await client.downloadSnapshot(
                        of: repoID,
                        matching: Self.modelFilePatterns,
                        progressHandler: { continuation.yield($0) }
                    )

                    try Task.checkCancellation()

                    // Move — not copy — the cached files into place, then drop the now-empty
                    // cache entry, so the weights exist exactly once when this returns.
                    try Self.materialize(snapshot: snapshot, of: repoID, at: destination)
                    try? FileManager.default.removeItem(at: cache.repoDirectory(repo: repoID, kind: .model))

                    continuation.finish()
                } catch {
                    try? FileManager.default.removeItem(at: Self.stagingDirectory(for: destination))
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// The scratch directory a download is assembled in before being swapped into place.
    private static func stagingDirectory(for destination: URL) -> URL {
        destination
            .deletingLastPathComponent()
            .appending(path: ".\(destination.lastPathComponent).partial", directoryHint: .isDirectory)
    }

    /// Moves a cached snapshot into its final flat model directory.
    ///
    /// Files are assembled in a sibling staging directory and swapped in at the end, so an
    /// interrupted download can never leave a half-populated model where the app expects a
    /// working one.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    private static func materialize(snapshot: URL, of repoID: Repo.ID, at destination: URL) throws {
        let fileManager = FileManager.default
        let staging = stagingDirectory(for: destination)

        try? fileManager.removeItem(at: staging)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)

        guard
            let enumerator = fileManager.enumerator(
                at: snapshot,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            )
        else {
            throw HuggingFaceError.invalidCache
        }

        var hasWeights = false

        while let fileURL = enumerator.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values.isRegularFile == true || values.isSymbolicLink == true else { continue }

            // Entries under snapshots/ are symlinks into blobs/. Move the blob itself,
            // otherwise deleting the cache below would leave a dangling link.
            let source = fileURL.resolvingSymlinksInPath()
            let relativePath = fileURL.path(percentEncoded: false)
                .replacingOccurrences(of: snapshot.path(percentEncoded: false), with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let target = staging.appending(path: relativePath)

            try fileManager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fileManager.removeItem(at: target)
            try fileManager.moveItem(at: source, to: target)

            if target.pathExtension == "safetensors" { hasWeights = true }
        }

        guard hasWeights else {
            try? fileManager.removeItem(at: staging)
            throw HuggingFaceError.noWeightsInRepository(repoID.description)
        }

        // A model is only listable if a standalone .jinja template sits next to the weights.
        // Most repos ship one; the rest carry the template inside tokenizer_config.json.
        try ensureChatTemplate(in: staging, of: repoID)

        if fileManager.fileExists(atPath: destination.path(percentEncoded: false)) {
            _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
        } else {
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.moveItem(at: staging, to: destination)
        }
    }

    /// Guarantees the model directory contains a `.jinja` chat template, extracting one from
    /// `tokenizer_config.json` when the repository does not ship a standalone file.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    private static func ensureChatTemplate(in directory: URL, of repoID: Repo.ID) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [])

        guard !contents.contains(where: { $0.pathExtension == "jinja" }) else { return }

        let tokenizerConfig = directory.appending(path: "tokenizer_config.json")

        guard
            let data = try? Data(contentsOf: tokenizerConfig),
            let template = TokenizerConfig.chatTemplate(from: data)
        else {
            try? fileManager.removeItem(at: directory)
            throw HuggingFaceError.missingChatTemplate(repoID.description)
        }

        try Data(template.utf8).write(to: directory.appending(path: "chat_template.jinja"))
    }
}

/// The subset of `tokenizer_config.json` needed to recover a chat template.
///
/// Hugging Face allows `chat_template` to be either a single template string or an array of
/// named templates; both forms appear in `mlx-community` repositories.
///
/// - Authored by: Claude Opus 5 (Anthropic)
private enum TokenizerConfig {
    private struct NamedTemplate: Decodable {
        let name: String
        let template: String
    }

    static func chatTemplate(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rawTemplate = object["chat_template"]
        else {
            return nil
        }

        if let template = rawTemplate as? String {
            return template
        }

        guard
            let array = try? JSONSerialization.data(withJSONObject: rawTemplate),
            let templates = try? JSONDecoder().decode([NamedTemplate].self, from: array),
            !templates.isEmpty
        else {
            return nil
        }

        return (templates.first { $0.name == "default" } ?? templates[0]).template
    }
}
