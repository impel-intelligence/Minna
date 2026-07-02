//
//  ToolCallView.swift
//  Minna
//
//  Created by Taylor Lineman on 7/2/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-07-02
//

import SwiftUI
import AnyLanguageModel
import DatabaseSchema

struct ToolCallsView: View {
    let toolCalls: Transcript.ToolCalls
    let theme: ThemeColor
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(toolCalls) { call in
                OneToolCallView(toolCall: call)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(2)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(theme.background, lineWidth: 2)
        )
    }
    
    struct OneToolCallView: View {
        let toolCall: Transcript.ToolCall
        
        var body: some View {
            DisclosureGroup {
                GeneratedContentView(content: toolCall.arguments, level: 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
            } label: {
                HStack {
                    Text("Ran Tool:")
                        .foregroundStyle(.secondary)
                    Text(toolCall.toolName)
                }
            }
        }
    }
}


#Preview {
    // swiftlint:disable force_try
    let arguments = try! GeneratedContent(json: #"{"city":"Cupertino"}"#)
    // swiftlint:enable force_try
    let toolCall = Transcript.ToolCall(id: "call-id", toolName: "getWeather", arguments: arguments)

    ToolCallsView(toolCalls: .init([
        toolCall
    ]), theme: .azure)
    .frame(height: 200)
}
