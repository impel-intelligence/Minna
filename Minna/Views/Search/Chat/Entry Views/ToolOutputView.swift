//
//  ToolOutputView.swift
//  Minna
//
//  Created by Taylor Lineman on 7/2/26.
//

import SwiftUI
import AnyLanguageModel
import DatabaseSchema

struct ToolOutputView: View {
    let output: Transcript.ToolOutput
    let theme: ThemeColor
    
    var body: some View {
        DisclosureGroup {
            ForEach(output.segments) { segment in
                SegmentView(segment: segment, isStreaming: false)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } label: {
            Text(output.toolName)
            Text("output")
                .foregroundStyle(.secondary)
        }
        .padding(2)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(theme.background, lineWidth: 2)
        )
    }
}

#Preview {
    ToolOutputView(output: Transcript.ToolOutput(
        id: "tool-output-id",
        toolName: "getWeather",
        segments: [.text(.init(id: "tool-output-segment", content: "Sunny"))]
    ), theme: .azure)
    .frame(height: 200)
}
