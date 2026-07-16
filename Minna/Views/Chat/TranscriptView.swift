//
//  TranscriptView.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//

import AnyLanguageModel
import SwiftUI
import MinnaChat

struct TranscriptView: View {
    @State var chatter: Chatter
    
    var body: some View {
        GeometryReader { reader in
            ScrollView {
                if let chatInstance = chatter.chatInstance {
                    VStack {
                        ForEach(chatInstance.session.transcript) { entry in
                            switch entry {
                            case .instructions:
                                EmptyView()
                            case .prompt(let prompt):
                                UserMessage(prompt: prompt, proxy: reader)
                            case .toolCalls(let toolCalls):
                                ToolCallsView(toolCalls: toolCalls)
                            case .toolOutput(let toolOutput):
                                ToolOutputView(output: toolOutput)
                            case .response(let response):
                                let isStreaming = chatInstance.session.isResponding && entry.id == chatInstance.session.transcript.last?.id
                                AssistantMessage(response: response, proxy: reader, isStreaming: isStreaming)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        if chatInstance.waitingForResponse {
                            HStack {
                                BouncingBubbles(text: Wordlists.generatingContentQuips.randomElement() ?? "Generating")
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("No Model Selected")
                }
            }
            .defaultScrollAnchor(.bottom)
        }
    }
}
