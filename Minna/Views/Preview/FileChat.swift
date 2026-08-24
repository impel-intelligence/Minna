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
import ModelManager
import SentrySwift

struct FileChat: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.router) var navigationRouter
    @Environment(\.openWindow) var openWindow
    
    @Environment(ModelManager.self) var modelManager

    @State private var presentModelPicker: Bool = false
    
    @State private var citationHandler: CitationHandler = CitationHandler()
    
    @State var chatter: Chatter?
    let file: File
    
    var body: some View {
        GeometryReader { reader in
            ScrollView {
                if let chatter {
                    TranscriptView(chatter: chatter, limitSize: false, reader: reader)
                } else {
                    ProgressView()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            chatBox
        }
        .environment(citationHandler)
        .theme(file.color)
        .task {
            let instructions = AskFileInstructions(uuid: file.uuid, title: file.title)
            let tools: [AvailableTool] = [
                .getExcerptContext,
                .searchInDocument
            ]
            
            if let chat = file.chat {
                self.chatter = Chatter(chat: chat, instructions: instructions, availableTools: tools)
            } else {
                let chat = Chat.make(on: file)
                self.chatter = Chatter(chat: chat, instructions: instructions, availableTools: tools)
            }
            
            do {
                try await chatter?.gatherProviders(modelContext: modelContext, irisContext: irisContext)
            } catch {
                Log.logger.error("Failed to reload providers", error: error)
            }
        }
        .task {
            let stream = NotificationCenter.default.messages(of: modelManager, for: DownloadDidFinish.self)
            for await _ in stream {
                do {
                    try await chatter?.gatherProviders(modelContext: modelContext, irisContext: irisContext)
                } catch {
                    Log.logger.error("Failed to reload providers", error: error)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .configuredProvidersChanged)) { _ in
            Task {
                do {
                    try await chatter?.gatherProviders(modelContext: modelContext, irisContext: irisContext)
                } catch {
                    Log.logger.error("Failed to reload providers", error: error)
                }
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            do {
                try URLHandler.handle(url, context: modelContext, router: navigationRouter, openWindow: openWindow)
                return .handled
            } catch {
                Log.logger.error("Failed to handle url", error: error, metadata: ["url": "\(url)"])
                return .systemAction
            }
        })
        .onDisappear {
            // Once the view disappears from the hierarchy, stop the current chat then clear the MLX cache.
            chatter?.chatInstance?.cancel()
            
            Task {
                await chatter?.chatInstance?.clearCache()
            }
        }
    }
    
    var chatBox: some View {
        VStack(alignment: .leading) {
            if let chatterBinding = Binding($chatter) {
                HStack {
                    Button {
                        presentModelPicker.toggle()
                    } label: {
                        if let selectedModel = chatter?.selectedModel {
                            ModelName(model: selectedModel)
                        } else {
                            Text("No Model Selected")
                        }
                    }
                    .popover(isPresented: $presentModelPicker) {
                        ModelSelector(providerDatabase: chatterBinding.providerDatabase, selectedModel: chatterBinding.selectedModel) { model, provider in
                            chatter?.selectedModel = model
                            chatter?.selectedProvider = provider
                            chatter?.initializeChatInstance(modelContext: modelContext, irisContext: irisContext, provider: provider, model: model)
                        }
                    }
                    .buttonStyle(.glass)
                    Spacer()
                    Button {
                        do {
                            guard let current = chatter else { return }
                            let selectedModel = current.selectedModel
                            let selectedProvider = current.selectedProvider
                            let oldChat = current.chat
                            file.chat = nil
                            
                            try modelContext.save()

                            let newChat = Chat.make(on: file)
                            modelContext.insert(newChat)
                            modelContext.delete(oldChat)
                            
                            try modelContext.save()

                            chatter = Chatter(chat: newChat, instructions: current.instructions, availableTools: current.availableTools)
                            chatter?.selectedModel = selectedModel
                            chatter?.selectedProvider = selectedProvider
                            
                            if let selectedModel, let selectedProvider {
                                chatter?.initializeChatInstance(modelContext: modelContext, irisContext: irisContext, provider: selectedProvider, model: selectedModel)
                            }
                        } catch {
                            Log.logger.error("Failed to clear chat and create a new one", error: error)
                            SentrySDK.capture(error: error)
                        }
                    } label: {
                        Image(systemSymbol: .xmark)
                            .accessibilityLabel("Clear Chat")
                    }
                }

                IndexingSearchBar(placeHolder: "Ask anything about \(file.title)", searchQuery: chatterBinding.chatMessage, isGenerating: chatterBinding.isGenerating) {
                    Task {
                        do {
                            if let model = chatter?.selectedModel {
                                TelemetryWrapper.chat(model: model.id, location: .askDoc)
                            } else {
                                TelemetryWrapper.chat(model: "unknown", location: .askDoc)
                            }

                            try await chatter?.submit()
                        } catch {
                            Log.logger.error("Failed to send chat", error: error)
                        }
                    }
                } cancel: {
                    chatter?.chatInstance?.cancel()
                }
                .padding(.bottom, 20)
            }
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
