//
//  FileChat.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//

import SwiftUI
import MinnaChat
import SwiftData
import DatabaseSchema
import SFSafeSymbols
import Logging

struct FileChat: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.router) var navigationRouter
    @Environment(\.openWindow) var openWindow
    @Environment(\.database) var database

    @State private var presentModelPicker: Bool = false
    
    @State private var citationHandler: CitationHandler = CitationHandler()
    
    @State var chatter: Chatter
    let file: File
    let didMakeNewChat: Bool

    init(file: File) {
        self.file = file
        let instructions = AskFileInstructions(uuid: file.uuid, title: file.title)
        let tools: [AvailableTool] = [
            .getExcerptContext,
            .searchInDocument
        ]
        
        if let chat = file.chat {
            self._chatter = State(initialValue: Chatter(chat: chat, instructions: instructions, availableTools: tools))
            didMakeNewChat = false
        } else {
            let chat = Chat.make(on: file)
            self._chatter = State(initialValue: Chatter(chat: chat, instructions: instructions, availableTools: tools))
            didMakeNewChat = true
        }
    }
    
    var body: some View {
        GeometryReader { reader in
            ScrollView {
                TranscriptView(chatter: chatter, limitSize: false, reader: reader)
            }
        }
        .safeAreaInset(edge: .bottom) {
            chatBox
        }
        .environment(citationHandler)
        .theme(chatter.chat.theme)
        .task {
            if didMakeNewChat {
                modelContext.insert(chatter.chat)
            }
            
            do {
                try await chatter.gatherProviders(modelContext: modelContext, irisContext: irisContext)
            } catch {
                Log.logger.error("Failed to gather providers", error: error)
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            do {
                try URLHandler.handle(url, database: database, router: navigationRouter, openWindow: openWindow, irisContext: irisContext)
                return .handled
            } catch {
                Log.logger.error("Failed to handle url", error: error, metadata: ["url": "\(url)"])
                return .systemAction
            }
        })
    }
    
    var chatBox: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    presentModelPicker.toggle()
                } label: {
                    if let selectedModel = chatter.selectedModel {
                        ModelName(model: selectedModel)
                    } else {
                        Text("No Model Selected")
                    }
                }
                .popover(isPresented: $presentModelPicker) {
                    ModelSelector(providerDatabase: $chatter.providerDatabase, selectedModel: $chatter.selectedModel, selectedProvider: $chatter.selectedProvider)
                }
                .buttonStyle(.glass)
                Spacer()
//                Button {
//                    
//                } label: {
//                    Label("Clear Chat", systemSymbol: .xmark)
//                }
//                .buttonStyle(.glass)

            }
            // TODO: Put back
            SearchBar(placeHolder: "Ask anything about \(file.title)", searchQuery: $chatter.chatMessage) {
                Task {
                    do {
                        try await chatter.submit()
                    } catch {
                        Log.logger.error("Failed to send chat", error: error)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}

//#Preview {
//    @Previewable var controller = IrisDBController(modelContainer: SampleDatabase.shared.modelContainer)
//    
//    AskMinnaView(chat: Chat.make(in: SampleDatabase.shared.sampleFolders.first!), viewMode: .chat) {
//        
//    }
//    .irisContext(controller.mainContext)
//    .modelContext(SampleDatabase.shared.context)
//}
