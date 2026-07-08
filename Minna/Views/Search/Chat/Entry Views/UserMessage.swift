//
//  UserMessage.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import DatabaseSchema
import Textual
import AnyLanguageModel

struct UserMessage: View {
    @Environment(\.theme) var theme: ThemeColor

    let prompt: Transcript.Prompt
    let proxy: GeometryProxy
    
    var body: some View {
        ForEach(prompt.segments) { segment in
            if case .text(let text) = segment {
                HStack {
                    Spacer()
                    StructuredText(markdown: text.content)
                        .textual.textSelection(.enabled)
                        .textual.padding(.all, .fontScaled(0))
                        .padding(5)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .stroke(Color.border, lineWidth: 1)
                                .shadow(color: theme.background.opacity(0.35), radius: 10, x: 0, y: 0)
                        }
                        .frame(maxWidth: proxy.size.width * 2/3, alignment: .trailing)
                }
            }
        }
    }
}

#Preview {
    GeometryReader { reader in
        UserMessage(prompt: .init(segments: [.text(.init(content: "What was the."))]), proxy: reader)
    }
}
