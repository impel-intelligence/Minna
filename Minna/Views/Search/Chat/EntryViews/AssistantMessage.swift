//
//  AssistantMessage.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import DatabaseSchema
import Textual
import AnyLanguageModel

struct AssistantMessage: View {
    let response: Transcript.Response
    let proxy: GeometryProxy

    var body: some View {
        ForEach(response.segments) { segment in
            if case .text(let text) = segment {
                HStack {
                    StructuredText(markdown: text.content)
                        .textual.textSelection(.enabled)
                        .textual.codeBlockStyle(MinnaCodeBlockStyle(theme: .azure))
                    Spacer()
                }
            }
        }
    }
}
