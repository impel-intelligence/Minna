//
//  Entry.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//

import AnyLanguageModel

extension Array where Element == Transcript.Segment {
    var plainText: String {
        var builder = ""
        
        for segment in self {
            switch segment {
            case .text(let text):
                builder += text.content
            default: continue
            }
        }
        
        return builder
    }
}

extension Transcript.Entry {
    /// Concatenated plain text for entries we render as chat bubbles (nil for tool calls/instructions).
    var plainText: String? {
        switch self {
        case .instructions(let instructions):
            return instructions.segments.plainText
        case .prompt(let prompt):
            return prompt.segments.plainText
        case .toolCalls(let toolCalls):
            return toolCalls.toolResult
        case .toolOutput(let toolOutput):
            return toolOutput.toolName + ": " + toolOutput.toolResult
        case .response(let response):
            return response.segments.plainText
        }
    }
    
    var plainTextPreview: String? { plainText.map { String($0.prefix(140)) } }
//    var role: Role? { case .prompt: .user; case .response: .assistant; default: nil }
}

public extension Transcript.Response {
    static func tempResponse(content: String) -> Transcript.Response {
        Transcript.Response(assetIDs: [], segments: [Transcript.Segment.text(Transcript.TextSegment(content: content))])
    }
}
