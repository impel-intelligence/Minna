//
//  AssistantMessage.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import DatabaseSchema
import Textual

struct AssistantMessage: View {
    let message: Message
    let proxy: GeometryProxy

    var body: some View {
        HStack {
            StructuredText(markdown: message.textContent)
                .textual.textSelection(.enabled)
                .textual.codeBlockStyle(MinnaCodeBlockStyle(theme: .azure))
            Spacer()
        }
    }
}
