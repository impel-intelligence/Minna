//
//  BenchSuite.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import Foundation

/// A graded task plus the fixed corpus it is graded against.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct BenchSuite: Codable, Sendable {
    /// How the four scored axes combine into a single number.
    struct Weights: Codable, Sendable {
        var prompt: Double
        var tools: Double
        var speed: Double
        var size: Double

        static let `default` = Weights(prompt: 0.35, tools: 0.35, speed: 0.2, size: 0.1)
    }

    /// The ceiling used to normalize each speed and size measurement into a 0–1 score.
    struct Budgets: Codable, Sendable {
        /// Tokens per second at which the speed score saturates.
        var targetTokensPerSecond: Double
        /// Seconds to first token at which the latency score bottoms out.
        var maximumTimeToFirstToken: Double
        /// Bytes at which the size score bottoms out.
        var maximumBytes: Double

        static let `default` = Budgets(
            targetTokensPerSecond: 60,
            maximumTimeToFirstToken: 12,
            maximumBytes: 12_000_000_000
        )
    }

    var weights: Weights
    var budgets: Budgets
    var maximumSearches: Int

    /// Seconds a single task may run before it is abandoned and scored as a failure.
    /// Weak models routinely loop on tool calls forever; without this a run never finishes.
    var taskTimeoutSeconds: Double?

    /// How many times each task is run. These models sample non-deterministically, and the same
    /// task can swing tens of points between runs, so a single sample cannot separate a better
    /// model from a luckier one. Scores are aggregated by median across repeats.
    var repeats: Int?

    var tasks: [BenchTask]

    var taskTimeout: Double { taskTimeoutSeconds ?? 180 }
    var repeatCount: Int { max(1, repeats ?? 3) }

    static func load(from url: URL) throws -> BenchSuite {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(BenchSuite.self, from: data)
    }
}

/// One prompt sent to a model, with everything needed to grade the answer without a human.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct BenchTask: Codable, Sendable, Identifiable {
    /// What behaviour the task is probing, which decides how it is graded.
    enum Kind: String, Codable, Sendable {
        /// A fact that sits in one document.
        case retrieval
        /// A fact that requires combining two documents.
        case multiHop
        /// The answer needs text surrounding a matched excerpt.
        case excerptContext
        /// Nothing in the corpus answers this; the model must say so.
        case refusal
        /// Underspecified; the model should search then ask for clarification.
        case ambiguous
        /// Several claims from several documents, each needing its own citation.
        case citationStress
    }

    var id: String
    var kind: Kind
    var prompt: String

    /// Document UUIDs that a correct answer must cite.
    var expectedDocumentIDs: [String]

    /// Substrings a correct answer must contain, matched case-insensitively.
    /// Each entry may list alternatives; any one of them satisfies it.
    var expectedFacts: [[String]]

    /// Substrings that must not appear — used to catch answers drawn from world knowledge
    /// rather than from the corpus.
    var forbiddenSubstrings: [String]

    /// Tool names the task should provoke at least one call to.
    var expectedTools: [String]

    /// Whether the answer must carry at least one citation tag.
    var requiresCitations: Bool

    /// Whether the answer must end with a question, for tasks that are deliberately ambiguous.
    var requiresClarifyingQuestion: Bool
}
