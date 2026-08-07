//
//  Graders.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import Foundation

/// A single pass/fail grading criterion with the weight it carries inside its axis.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct Check: Codable, Sendable {
    let name: String
    let passed: Bool
    let weight: Double
    let detail: String?

    init(_ name: String, _ passed: Bool, weight: Double = 1, detail: String? = nil) {
        self.name = name
        self.passed = passed
        self.weight = weight
        self.detail = detail
    }
}

extension Array where Element == Check {
    /// The weighted fraction of checks that passed, in the range 0–1.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var score: Double {
        let total = reduce(0) { $0 + $1.weight }
        guard total > 0 else { return 1 }
        return reduce(0) { $0 + ($1.passed ? $1.weight : 0) } / total
    }
}

/// A citation tag parsed out of a model's answer.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct ParsedCitation: Sendable, Codable {
    let documentID: String
    let title: String
    let excerpt: Int
}

/// Grades how closely an answer followed `AskMinnaInstructions`.
///
/// Everything here is checkable without a judge model: the instructions specify an exact citation
/// format, forbid answering from outside the corpus, and cap the number of searches.
///
/// - Authored by: Claude Opus 5 (Anthropic)
enum PromptGrader {
    /// Matches the exact tag the instructions mandate, in the order they mandate.
    static var citationPattern: Regex<(Substring, Substring, Substring, Substring)> {
        /<cite\s+doc_id="([^"]*)"\s+title="([^"]*)"\s+excerpt="([^"]*)"\s*\/>/
    }

    /// Matches anything that is trying to be a citation, so malformed tags can be counted
    /// rather than silently ignored.
    static var looseCitationPattern: Regex<Substring> {
        /<\s*cite\b[^>]*>/
    }

    static func citations(in answer: String) -> [ParsedCitation] {
        answer.matches(of: citationPattern).map { match in
            ParsedCitation(
                documentID: String(match.1),
                title: String(match.2),
                excerpt: Int(match.3) ?? -1
            )
        }
    }

    static func malformedCitationCount(in answer: String) -> Int {
        answer.matches(of: looseCitationPattern).count - answer.matches(of: citationPattern).count
    }

    /// Grades one answer against its task.
    ///
    /// - Parameters:
    ///   - answer: The model's final response text.
    ///   - task: The task being graded.
    ///   - corpus: Every document in the fixture corpus, for validating citation targets.
    ///   - retrievedDocumentIDs: Document UUIDs the tools actually returned during this turn.
    /// - Returns: The checks making up the prompt-adherence axis.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func grade(
        answer: String,
        task: BenchTask,
        corpus: [CorpusDocument],
        retrievedDocumentIDs: Set<String>
    ) -> [Check] {
        var checks: [Check] = []

        let citations = citations(in: answer)
        let malformed = malformedCitationCount(in: answer)
        let citedIDs = Set(citations.map { $0.documentID.lowercased() })
        let corpusIDs = Set(corpus.map { $0.uuid.uuidString.lowercased() })
        let normalizedAnswer = answer.lowercased()

        checks.append(Check("produced an answer", !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, weight: 2))
        checks.append(Check("no malformed citation tags", malformed == 0, detail: malformed > 0 ? "\(malformed) malformed" : nil))

        if task.requiresCitations {
            checks.append(Check("cited at least one document", !citations.isEmpty, weight: 2))

            let allReal = citations.allSatisfy { corpusIDs.contains($0.documentID.lowercased()) }
            checks.append(
                Check(
                    "every cited doc_id exists",
                    citations.isEmpty ? false : allReal,
                    weight: 2,
                    detail: allReal ? nil : "hallucinated document ids"
                )
            )

            let allRetrieved = citations.allSatisfy { retrievedDocumentIDs.contains($0.documentID.lowercased()) }
            checks.append(
                Check(
                    "every cited doc_id was actually retrieved",
                    citations.isEmpty ? false : allRetrieved,
                    weight: 2,
                    detail: allRetrieved ? nil : "cited a document the tools never returned"
                )
            )

            let excerptCounts = Dictionary(uniqueKeysWithValues: corpus.map { ($0.uuid.uuidString.lowercased(), $0.excerpts.count) })
            let excerptsInRange = citations.allSatisfy { citation in
                guard let count = excerptCounts[citation.documentID.lowercased()] else { return false }
                return citation.excerpt >= 0 && citation.excerpt < count
            }
            checks.append(Check("every excerpt index is in range", citations.isEmpty ? false : excerptsInRange))

            let expected = Set(task.expectedDocumentIDs.map { $0.lowercased() })
            if !expected.isEmpty {
                checks.append(
                    Check(
                        "cited the expected document(s)",
                        expected.isSubset(of: citedIDs),
                        weight: 3,
                        detail: expected.subtracting(citedIDs).isEmpty ? nil : "missing \(expected.subtracting(citedIDs).count)"
                    )
                )
            }
        } else {
            checks.append(
                Check(
                    "did not fabricate citations",
                    citations.isEmpty,
                    weight: 3,
                    detail: citations.isEmpty ? nil : "cited \(citations.count) documents for an unanswerable question"
                )
            )
        }

        for alternatives in task.expectedFacts {
            let found = alternatives.contains { normalizedAnswer.contains($0.lowercased()) }
            checks.append(
                Check(
                    "states \"\(alternatives[0])\"",
                    found,
                    weight: 3,
                    detail: found ? nil : "fact missing from the answer"
                )
            )
        }

        for forbidden in task.forbiddenSubstrings {
            let present = normalizedAnswer.contains(forbidden.lowercased())
            checks.append(
                Check(
                    "avoids out-of-corpus claim \"\(forbidden)\"",
                    !present,
                    weight: 3,
                    detail: present ? "answered from world knowledge" : nil
                )
            )
        }

        if task.requiresClarifyingQuestion {
            checks.append(Check("asked a clarifying question", answer.contains("?"), weight: 2))
        }

        if task.requiresCitations, !citations.isEmpty {
            checks.append(
                Check(
                    "citations sit at sentence ends",
                    citationCoverage(in: answer) >= 0.5,
                    detail: String(format: "coverage %.0f%%", citationCoverage(in: answer) * 100)
                )
            )
        }

        return checks
    }

    /// The fraction of sentences carrying a citation, used as a soft grounding signal.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func citationCoverage(in answer: String) -> Double {
        let sentences = answer
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 40 }

        guard !sentences.isEmpty else { return 1 }

        let cited = sentences.filter { $0.contains("<cite ") }.count
        return Double(cited) / Double(sentences.count)
    }
}

/// Grades whether the model drove Minna's tools correctly.
///
/// - Authored by: Claude Opus 5 (Anthropic)
enum ToolGrader {
    static let searchToolNames: Set<String> = ["searchDocuments", "searchInDocument"]
    static let knownToolNames: Set<String> = ["searchDocuments", "searchInDocument", "getDocument", "getExcerptContext"]

    /// Grades one turn's tool traffic against its task.
    ///
    /// - Parameters:
    ///   - invocations: Every tool call the model made, in order.
    ///   - task: The task being graded.
    ///   - maximumSearches: The search cap stated in the instructions.
    ///   - hitToolLoopCap: Whether generation stopped because the tool-call loop ran out of iterations.
    ///   - failure: The error that ended generation, if any.
    /// - Returns: The checks making up the tool-adherence axis.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func grade(
        invocations: [ToolInvocation],
        task: BenchTask,
        maximumSearches: Int,
        hitToolLoopCap: Bool,
        failure: String?
    ) -> [Check] {
        var checks: [Check] = []

        // AnyLanguageModel aborts when a model reissues an identical tool call, and the aborted
        // call never reaches the observer — so the repeat check below cannot see it. Without this,
        // a model that loops scores a clean 100% on tool use.
        let abortReason = failure.flatMap(toolLoopAbortReason)
        checks.append(
            Check(
                "generation was not aborted on a tool loop",
                abortReason == nil,
                weight: 4,
                detail: abortReason
            )
        )

        let names = invocations.map { $0.toolName }
        let searches = names.filter { searchToolNames.contains($0) }

        checks.append(Check("called at least one tool", !invocations.isEmpty, weight: 3))

        let unknown = Set(names).subtracting(knownToolNames)
        checks.append(
            Check(
                "never invented a tool name",
                unknown.isEmpty,
                weight: 2,
                detail: unknown.isEmpty ? nil : unknown.sorted().joined(separator: ", ")
            )
        )

        checks.append(
            Check(
                "started with a search",
                names.first.map { searchToolNames.contains($0) } ?? false,
                weight: 2
            )
        )

        checks.append(
            Check(
                "stayed within \(maximumSearches) searches",
                searches.count <= maximumSearches,
                weight: 2,
                detail: searches.count > maximumSearches ? "made \(searches.count)" : nil
            )
        )

        checks.append(Check("did not exhaust the tool-call loop", !hitToolLoopCap, weight: 2))

        let repeats = invocations.count - Set(invocations.map { "\($0.toolName)|\($0.arguments)" }).count
        checks.append(
            Check(
                "no repeated identical calls",
                repeats == 0,
                detail: repeats > 0 ? "\(repeats) repeats" : nil
            )
        )

        let argumentsValid = invocations.allSatisfy { invocation in
            guard searchToolNames.contains(invocation.toolName) else { return true }
            // The tool declares nItems must be greater than zero; small models routinely send 0.
            // Arguments are JSON; nItems may arrive as 5 or 5.0 depending on the model.
            guard let match = invocation.arguments.firstMatch(of: /"nItems"\s*:\s*"?(-?\d+(?:\.\d+)?)"?/) else { return false }
            return (Double(match.1) ?? 0) > 0
        }
        checks.append(Check("search arguments satisfy their guides", argumentsValid, weight: 2))

        let failedOutputs = invocations.filter { $0.output.hasPrefix("Failed to run search") }.count
        checks.append(
            Check(
                "no tool call errored",
                failedOutputs == 0,
                detail: failedOutputs > 0 ? "\(failedOutputs) failed" : nil
            )
        )

        for expected in task.expectedTools {
            checks.append(
                Check(
                    "used \(expected)",
                    names.contains(expected),
                    weight: 3
                )
            )
        }

        return checks
    }

    /// Describes why generation was aborted, when the cause was runaway tool calling.
    ///
    /// - Parameter failure: The error description recorded for the turn.
    /// - Returns: A short reason, or `nil` when the failure was unrelated to tool looping.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func toolLoopAbortReason(_ failure: String) -> String? {
        if failure.contains("repeated MLX tool-call signature") {
            return "reissued an identical tool call"
        }

        if failure.contains("maximum tool iterations") {
            return "exhausted the tool-call iteration limit"
        }

        return nil
    }

    /// Every document UUID the tools handed back this turn.
    ///
    /// `SearchTool` renders results as `uuid: {<UUID>}`, which is what this looks for.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func retrievedDocumentIDs(from invocations: [ToolInvocation]) -> Set<String> {
        var identifiers: Set<String> = []

        for invocation in invocations {
            for match in invocation.output.matches(of: /uuid:\s*\{([0-9A-Fa-f-]{36})\}/) {
                identifiers.insert(String(match.1).lowercased())
            }
        }

        return identifiers
    }
}

/// Turns raw timings and byte counts into 0–1 scores.
///
/// - Authored by: Claude Opus 5 (Anthropic)
enum ResourceGrader {
    /// Scores decode throughput and first-token latency against the suite's budgets.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func speedScore(
        tokensPerSecond: Double,
        timeToFirstToken: Double,
        budgets: BenchSuite.Budgets
    ) -> Double {
        let throughput = min(1, tokensPerSecond / budgets.targetTokensPerSecond)
        let latency = max(0, 1 - timeToFirstToken / budgets.maximumTimeToFirstToken)
        return 0.6 * throughput + 0.4 * latency
    }

    /// Scores a model's disk footprint, where smaller is better.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func sizeScore(bytes: Int64, budgets: BenchSuite.Budgets) -> Double {
        guard budgets.maximumBytes > 0 else { return 1 }
        return max(0, 1 - Double(bytes) / budgets.maximumBytes)
    }
}
