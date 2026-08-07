//
//  BenchCorpus.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import Foundation
import IrisCommon
import IrisSearch
import CoreMLEmbedder
import AppleIntelligenceEmbedder
import ModelCDN

/// A fixture document, parsed from a markdown file with a small YAML-ish header.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct CorpusDocument: Sendable {
    let uuid: UUID
    let title: String
    let summary: String
    /// One entry per excerpt, in document order. Excerpt indices in citations refer to these.
    let excerpts: [String]
}

/// Builds the fixed `IrisDB` every model is benchmarked against.
///
/// The corpus is rebuilt from source on each run, in a temporary directory, using the same
/// `bge_small_en_v1.5` embedder the app ships. Retrieval is therefore identical for every model
/// under test, so score differences are attributable to the model rather than to search drift.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct BenchCorpus: Sendable {
    let database: IrisDB
    let documents: [CorpusDocument]
    let location: URL

    private static let embedderID = "bge_small_en_v1.5"

    /// Loads every `.md` fixture in `directory` and indexes it into a fresh database.
    ///
    /// - Parameters:
    ///   - directory: The directory holding the corpus markdown files.
    ///   - location: Where the database bundle should be written.
    /// - Returns: A ready-to-search corpus.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func build(from directory: URL, at location: URL) async throws -> BenchCorpus {
        let documents = try load(from: directory)

        try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)

        let database = try IrisDB(databaseLocation: location, textEmbedder: makeEmbedder())

        for document in documents {
            let content = document.excerpts.enumerated().map { offset, text in
                EmbeddableContent.text(
                    content: text,
                    location: DocumentLocation(
                        sequenceIndex: offset,
                        documentLength: document.excerpts.count,
                        anchor: .text(characterRange: 0 ..< text.count)
                    )
                )
            }

            _ = try await database.createDocument(
                uuid: document.uuid,
                title: document.title,
                description: document.summary,
                embeddableContent: content
            )
        }

        return BenchCorpus(database: database, documents: documents, location: location)
    }

    /// The embedder the app itself uses, falling back the same way `IrisDBController` does.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    private static func makeEmbedder() throws -> EmbeddingProvider {
        let directory = ManifestSharedSettings.modelStorageURL.appendingPathComponent(embedderID, conformingTo: .directory)

        if let embedder = try? CoreMLEmbedder(modelDirectory: directory) {
            return embedder
        }

        FileHandle.standardError.write(Data("warning: \(embedderID) not found, falling back to NLContextualEmbedder\n".utf8))

        if let embedder = try? NLContextualEmbedder(language: .english) {
            return embedder
        }

        return try NLEmbedder(language: .english)
    }

    /// Parses the corpus fixture format: a `---` delimited header of `key: value` pairs,
    /// followed by excerpts separated by `%%`.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    private static func load(from directory: URL) throws -> [CorpusDocument] {
        let files = try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return try files.map { file in
            let raw = try String(contentsOf: file, encoding: .utf8)
            let parts = raw.components(separatedBy: "---\n")

            guard parts.count >= 3 else {
                throw BenchError.malformedCorpusDocument(file.lastPathComponent)
            }

            var header: [String: String] = [:]

            for line in parts[1].split(separator: "\n") {
                guard let separator = line.firstIndex(of: ":") else { continue }
                let key = String(line[line.startIndex ..< separator]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
                header[key] = value
            }

            guard
                let rawUUID = header["uuid"], let uuid = UUID(uuidString: rawUUID),
                let title = header["title"],
                let summary = header["summary"]
            else {
                throw BenchError.malformedCorpusDocument(file.lastPathComponent)
            }

            let body = parts[2...].joined(separator: "---\n")
            let excerpts = body
                .components(separatedBy: "\n%%\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            return CorpusDocument(uuid: uuid, title: title, summary: summary, excerpts: excerpts)
        }
    }
}

enum BenchError: Error, LocalizedError {
    case malformedCorpusDocument(String)
    case missingResource(String)
    case modelNotFound(String)
    case noModelsSelected

    var errorDescription: String? {
        switch self {
        case .malformedCorpusDocument(let name):
            return "Corpus document \"\(name)\" is missing its uuid/title/summary header."
        case .missingResource(let name):
            return "Bundled resource \"\(name)\" is missing."
        case .modelNotFound(let id):
            return "No downloaded model named \"\(id)\". Run `modelbench list` to see what is available."
        case .noModelsSelected:
            return "No models to benchmark."
        }
    }
}
