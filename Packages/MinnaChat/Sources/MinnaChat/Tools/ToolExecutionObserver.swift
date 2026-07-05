//
//  ToolExecutionObserver.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/29/26.
//
//

import AnyLanguageModel
import Foundation

actor ToolExecutionObserver: ToolExecutionDelegate {
    var searchedDocuments: [UUID] = []
    
    func didGenerateToolCalls(_ toolCalls: [Transcript.ToolCall], in session: LanguageModelSession) async {
        print("Generated tool calls: \(toolCalls)")
    }

    func toolCallDecision(for toolCall: Transcript.ToolCall, in session: LanguageModelSession) async -> ToolExecutionDecision {
        // Return .stop to halt after tool calls, or .provideOutput(...) to bypass execution.
        // This is a good place to ask the user for confirmation (for example, in a modal dialog).
        .execute
    }

    func didExecuteToolCall(_ toolCall: Transcript.ToolCall, output: Transcript.ToolOutput, in session: LanguageModelSession) async {
        if toolCall.toolName == "searchDocuments" {
            print(output.segments)
        }
        
        print("Executed tool call: \(toolCall)")
    }
}
