//
//  BenchObserver.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import AnyLanguageModel
import Foundation

/// A record of one tool invocation, captured as the model makes it.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct ToolInvocation: Sendable, Codable {
    let toolName: String
    let arguments: String
    let output: String
    /// Seconds from the start of the turn to the moment the call was generated.
    let offset: Double
}

/// Watches a session's tool traffic so the harness can grade tool use without re-parsing
/// the transcript's encoding.
///
/// This mirrors `MinnaChat`'s own `ToolExecutionObserver`, which is internal to that module.
///
/// - Authored by: Claude Opus 5 (Anthropic)
actor BenchObserver: ToolExecutionDelegate {
    private var invocations: [ToolInvocation] = []
    private var pendingArguments: [String: String] = [:]
    private var start: ContinuousClock.Instant = .now

    func beginTurn() {
        invocations.removeAll()
        pendingArguments.removeAll()
        start = .now
    }

    func recordedInvocations() -> [ToolInvocation] {
        invocations
    }

    func didGenerateToolCalls(_ toolCalls: [Transcript.ToolCall], in session: LanguageModelSession) async {
        for toolCall in toolCalls {
            // jsonString, not String(describing:) — the latter renders as
            // `GeneratedContent(structure(properties: ["nItems": GeneratedContent(number(5.0))]))`,
            // which no argument check can reasonably parse.
            pendingArguments[toolCall.id] = toolCall.arguments.jsonString
        }
    }

    func toolCallDecision(for toolCall: Transcript.ToolCall, in session: LanguageModelSession) async -> ToolExecutionDecision {
        .execute
    }

    func didExecuteToolCall(_ toolCall: Transcript.ToolCall, output: Transcript.ToolOutput, in session: LanguageModelSession) async {
        invocations.append(
            ToolInvocation(
                toolName: toolCall.toolName,
                arguments: pendingArguments[toolCall.id] ?? String(describing: toolCall.arguments),
                output: output.segments.textContent,
                offset: (ContinuousClock.now - start).seconds
            )
        )
    }
}

extension Array where Element == Transcript.Segment {
    /// The concatenated content of every segment.
    ///
    /// Structured segments must be included: Minna's tools return their results as structured
    /// content, so reading only `.text` segments yields an empty string and makes every
    /// "was this document actually retrieved" check fail regardless of the model.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var textContent: String {
        compactMap { segment in
            switch segment {
            case .text(let textSegment):
                return textSegment.content
            case .structure(let structuredSegment):
                return structuredSegment.content.jsonString
            case .image:
                return nil
            }
        }
        .joined(separator: "\n")
    }
}
