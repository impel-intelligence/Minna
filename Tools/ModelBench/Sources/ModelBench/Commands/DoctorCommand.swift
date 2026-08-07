//
//  DoctorCommand.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import ArgumentParser
import Foundation
import IrisSearch

/// Checks the suite against the corpus without running any model.
///
/// A task whose expected documents are not retrievable is unpassable, and would otherwise look
/// like every model failing rather than a broken fixture. Run this after editing the corpus or
/// the suite.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct Doctor: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Verify the corpus can answer the suite, without running a model."
    )

    @Option(name: .long, help: "Path to a suite JSON file. Defaults to the bundled suite.")
    var suite: String?

    @Option(name: .long, help: "Path to a corpus directory. Defaults to the bundled corpus.")
    var corpus: String?

    @Option(name: .long, help: "How many results to request per search.")
    var results: Int = 5

    func run() async throws {
        let suiteURL = try suite.map { URL(fileURLWithPath: $0) } ?? Resources.suite()
        let corpusURL = try corpus.map { URL(fileURLWithPath: $0) } ?? Resources.corpus()
        let loadedSuite = try BenchSuite.load(from: suiteURL)

        let location = FileManager.default.temporaryDirectory.appending(path: "modelbench-doctor-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: location) }

        let builtCorpus = try await BenchCorpus.build(from: corpusURL, at: location)
        print("Corpus: \(builtCorpus.documents.count) documents, \(builtCorpus.documents.reduce(0) { $0 + $1.excerpts.count }) excerpts")

        var identifiers: Set<String> = []
        var problems = 0

        for document in builtCorpus.documents {
            let identifier = document.uuid.uuidString.lowercased()
            if !identifiers.insert(identifier).inserted {
                print("✗ duplicate uuid \(identifier)")
                problems += 1
            }
        }

        print("")
        print("Task checks (searching with the task prompt, top \(results)):")

        for task in loadedSuite.tasks {
            let searchResults = try await builtCorpus.database.search(query: .init(text: task.prompt), nItems: results)
            let returned = Set(searchResults.map { $0.document.uuid.uuidString.lowercased() })
            let expected = Set(task.expectedDocumentIDs.map { $0.lowercased() })

            // Every expected document id must exist in the corpus at all.
            let unknown = expected.subtracting(identifiers)

            if !unknown.isEmpty {
                print("✗ \(task.id): expects document(s) not in the corpus: \(unknown.sorted().joined(separator: ", "))")
                problems += 1
                continue
            }

            let missing = expected.subtracting(returned)

            if missing.isEmpty {
                let detail = expected.isEmpty ? "no expected documents" : "all \(expected.count) retrievable"
                print("✓ \(task.id): \(detail), search returned \(returned.count)")
            } else {
                // Multi-hop and citation-stress tasks are meant to need more than one query, so a
                // single prompt-shaped search missing a document is expected. What matters is that
                // the document is reachable by *some* search the model could plausibly run.
                let reachable = try await reachableByTitle(missing, in: builtCorpus)

                if reachable == missing, task.kind == .multiHop || task.kind == .citationStress {
                    print("✓ \(task.id): \(missing.count) document(s) need a second, more specific search — by design for \(task.kind.rawValue)")
                } else {
                    let unreachable = missing.subtracting(reachable)
                    print("✗ \(task.id): \(unreachable.count) expected document(s) are not retrievable by any probe — the task is unpassable")
                    problems += 1
                }
            }

            // A refusal task is only meaningful if the corpus genuinely lacks the answer.
            if task.kind == .refusal, !searchResults.isEmpty {
                let titles = searchResults.prefix(2).map { $0.document.title }.joined(separator: ", ")
                print("  note: search still returned \(searchResults.count) result(s) (\(titles)); the model must recognise they are irrelevant")
            }
        }

        // Every fact the suite expects must actually appear somewhere in the corpus.
        print("")
        print("Fact checks:")

        let allText = builtCorpus.documents
            .flatMap { [$0.title, $0.summary] + $0.excerpts }
            .joined(separator: "\n")
            .lowercased()

        for task in loadedSuite.tasks {
            for alternatives in task.expectedFacts where !alternatives.contains(where: { allText.contains($0.lowercased()) }) {
                print("✗ \(task.id): no document contains \"\(alternatives[0])\" — the check can never pass")
                problems += 1
            }

            for forbidden in task.forbiddenSubstrings where allText.contains(forbidden.lowercased()) {
                print("✗ \(task.id): \"\(forbidden)\" is forbidden but appears in the corpus — a correct answer would be penalised")
                problems += 1
            }
        }

        print("")

        if problems == 0 {
            print("✓ suite and corpus are consistent")
        } else {
            print("✗ \(problems) problem(s) found")
            throw ExitCode.failure
        }
    }

    /// Of `identifiers`, those a search for the document's own title can surface.
    ///
    /// Used to distinguish "this document needs a second, more specific query" from
    /// "this document cannot be retrieved at all".
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    private func reachableByTitle(_ identifiers: Set<String>, in corpus: BenchCorpus) async throws -> Set<String> {
        var reachable: Set<String> = []

        for identifier in identifiers {
            guard let document = corpus.documents.first(where: { $0.uuid.uuidString.lowercased() == identifier }) else { continue }

            let searchResults = try await corpus.database.search(query: .init(text: document.title), nItems: results)

            if searchResults.contains(where: { $0.document.uuid.uuidString.lowercased() == identifier }) {
                reachable.insert(identifier)
            }
        }

        return reachable
    }
}
