//
//  StreamingText.swift
//  Minna
//
//  Created by Taylor Lineman on 7/6/26.
//

import SwiftUI
import Textual

struct StreamingStructuredText: View {
    @Environment(CitationHandler.self) var handler
    @State var typewriter: TypewritingEngine = TypewritingEngine()
    
    var content: String
    var isStreaming: Bool
    
    var body: some View {
        StructuredText(typewriter.displayedText, parser: handler)
            .onChange(of: content, initial: true) { _, newValue in
                typewriter.update(with: newValue, isStreaming: isStreaming)
            }
    }
}

#Preview {
    StreamingStructuredText(content: "Hello World this is a test of text that should stream out. Hello World this is a test of text that should stream out. Hello World this is a test of text that should stream out. Hello World this is a test of text that should stream out", isStreaming: true)
        .frame(width: 300, height: 300)
        .environment(CitationHandler())
}
