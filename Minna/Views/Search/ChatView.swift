//
//  ChatView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

import SwiftUI
import MinnaChat
import SwiftData
import DatabaseSchema
import Textual
import SFSafeSymbols
import ModelManager

struct ChatView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(ModelDownloader.self) var modelDownloader
    
    @Query(sort: \Message.createdAt) private var messages: [Message]

    @State var chatInstance: ChatInstance?
    @State var chatMessage: String = ""
    @State var downloadProgress: Progress?
    
    let chat: Chat = Chat()

    var body: some View {
        GeometryReader { reader in
            ScrollView {
                VStack {
                    ForEach(messages) { message in
                        switch message.owner {
                        case .assistant:
                            AssistantMessage(message: message, proxy: reader)
                                .border(.green)
                        case .user:
                            UserMessage(message: message, proxy: reader)
                                .border(.blue)
                        }
                    }
                    if let generatingMessage = chatInstance?.generatingMessage {
                        AssistantMessage(message: generatingMessage, proxy: reader)
                    }
                }
                .padding()
            }
            .border(.red)
            .defaultScrollAnchor(.bottom)
            .safeAreaInset(edge: .bottom) {
                chatBox
            }
        }
        .task {
            do {
                // We have to first download the model we need for chatting.
                for try await progress in try modelDownloader.downloadModel(id: "mlx-community/Qwen3.5-4B-4bit") {
                    self.downloadProgress = progress
                }
                
                self.downloadProgress = nil

                chatInstance = ChatInstance(irisDB: try irisContext.database, databaseContext: modelContext)
            } catch {
                print("Failed to get database \(error)")
            }
        }
    }
    
    var chatBox: some View {
        HStack {
            Spacer()
            if let downloadProgress {
                ProgressView(value: downloadProgress.fractionCompleted) {
                    Text("Downloading Chat Model:")
                } currentValueLabel: {
                    Text("\(downloadProgress.completedUnitCount) / \(downloadProgress.totalUnitCount)")
                }
                .frame(maxWidth: 500)
            } else {
                Image(.impelLogo)
                    .resizable()
                    .frame(width: 36, height: 36)
                    .accessibilityLabel("Minna Logo")
                SearchBar(placeHolder: "Search or Ask for Anything", searchQuery: $chatMessage) {
                    Task {
                        let tmpMessage = chatMessage
                        chatMessage = ""
                        
                        let userMessage = Message(chat: chat, owner: .user, textContent: tmpMessage)
                        modelContext.insert(userMessage)
                        
                        do {
                            try await chatInstance?.sendMessage(userMessage.textContent, in: chat)
                        } catch {
                            if chatMessage.isEmpty {
                                chatMessage = tmpMessage
                                modelContext.delete(userMessage)
                            }
                            print("Failed to send chat: \(error)")
                        }
                    }
                }
            }
            Spacer()
        }
        .padding([.bottom], 20)
    }
}

struct AssistantMessage: View {
    let message: Message
    let proxy: GeometryProxy

    var body: some View {
        StructuredText(markdown: message.textContent)
            .textual.textSelection(.enabled)
            .textual.codeBlockStyle(MinnaCodeBlockStyle(theme: .azure))
            .frame(width: proxy.size.width, alignment: .leading)
    }
}

struct UserMessage: View {
    let message: Message
    let proxy: GeometryProxy
    
    @State var isHovering: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()

                StructuredText(markdown: message.textContent)
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
        .clipShape(.rect)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    ChatView()
        .modelContext(SampleDatabase.shared.context)
        .environment(ModelDownloader())
}
