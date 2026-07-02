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
    let prompt: Transcript.Prompt
    let proxy: GeometryProxy
    
    @State var isHovering: Bool = false
    
    var body: some View {
        ForEach(prompt.segments) { segment in
            if case .text(let text) = segment {
                VStack {
                    HStack {
                        Spacer()
                        StructuredText(markdown: text.content)
                            .textual.textSelection(.enabled)
                            .textual.padding(.all, .fontScaled(0))
                            .padding(5)
                            .background(ThemeColor.azure.background)
                            .cornerRadius(8)
                            .frame(maxWidth: proxy.size.width * 2/3, alignment: .trailing)
                    }
                    //            if isHovering {
                    //                HStack {
                    //                    Spacer()
                    //                    Button {
                    //
                    //                    } label: {
                    //                        Label("Copy", systemSymbol: .documentOnDocument)
                    //                            .imageScale(.small)
                    //                    }
                    //                    .labelStyle(.iconOnly)
                    //                    .buttonStyle(.plain)
                    //                    Text(message.createdAt, style: .relative)
                    //                        .help(message.createdAt.formatted(date: .complete, time: .complete))
                    //                }
                    //                .font(.caption)
                    //                .foregroundStyle(.secondary)
                    //            }
                }
                .contentShape(.rect)
                .onHover { hovering in
                    isHovering = hovering
                }
            }
        }
    }
}
