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
    @Environment(CitationHandler.self) var handler
    @Environment(\.theme) var theme: ThemeColor

    let segment: Transcript.Segment
    /// True when this segment view is the one currently generating.
    let isStreaming: Bool

    var body: some View {
        switch segment {
        case .text(let text):
            StreamingStructuredText(content: text.content, isStreaming: isStreaming)
                .textual.textSelection(.enabled)
                .textual.codeBlockStyle(MinnaCodeBlockStyle(theme: theme))
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
