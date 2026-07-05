//
//  SegmentView.swift
//  Minna
//
//  Created by Taylor Lineman on 7/2/26.
//

import SwiftUI
import AnyLanguageModel
import Textual
import DatabaseSchema

struct SegmentView: View {
    let segment: Transcript.Segment
    
    var body: some View {
        switch segment {
        case .text(let text):
            StructuredText(markdown: text.content, syntaxExtensions: [
                .emoji(<#T##emoji: Set<Emoji>##Set<Emoji>#>)
            ])
                .textual.textSelection(.enabled)
                .textual.codeBlockStyle(MinnaCodeBlockStyle(theme: .azure))
        case .image(let image):
            switch image.source {
            case .url(let url):
                AsyncImage(url: url)
            case .data(let data, let mimeType):
                Text("Image Data: \(data.count), \(mimeType)")
            }
        case .structure(let structure):
            GeneratedContentView(content: structure.content, level: 0)
        }
    }
}
