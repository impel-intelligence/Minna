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
    let isStreaming: Bool

    var body: some View {
        VStack {
            ForEach(response.segments) { segment in
                HStack {
                    SegmentView(segment: segment, isStreaming: isStreaming)
                    Spacer()
                }
            }
        }
    }
}
