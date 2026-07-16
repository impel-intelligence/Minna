//
//  ChatView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-07-06.
//  Merged compose + chat into AskMinnaView by Claude Opus 4.8 (Anthropic) on 2026-07-08.
//  Mostly re-written by Taylor Lineman on 7/6/26
//

import SwiftUI
import MinnaChat
import SwiftData
import DatabaseSchema
import Textual
import SFSafeSymbols
import ModelManager
import ModernSettingsWindow
import OrderedCollections
import AnyLanguageModel

struct AskMinnaView: View {
    enum ViewMode {
        case startup
        case chat
    }
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.router) var navigationRouter

    @Namespace private var searchContainerTransitions

    @AppStorage(AppStorageKeys.preferredModel) var preferredModel: String = ""

    let chat: Chat
    
    @State var viewMode: ViewMode

    /// Invoked by the New Chat toolbar button. `nil` hides the button (e.g. when viewing an existing chat pushed from a folder).
    var newChat: (() -> Void)?

    @State private var citationHandler: CitationHandler = CitationHandler()

    @Query(sort: \ConfiguredProvider.name) private var providers: [ConfiguredProvider]
    @State private var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]> = [:]
    @State private var selectedProvider: ConfiguredProvider?
    @State private var selectedModel: Model?

    @State private var chatInstance: ChatInstance?
    @State private var chatMessage: String = ""

    @State private var presentModelPicker: Bool = false
    
    var body: some View {
        GeometryReader { reader in
            Group {
                switch viewMode {
                case .startup:
                    startup()
                case .chat:
                    transcript(reader: reader)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .theme(chat.theme)
        .navigationTitle(chat.title())
        .environment(citationHandler)
        .environment(\.openURL, OpenURLAction { url in
            do {
                try URLHandler.handle(url, context: modelContext, router: navigationRouter)
                return .handled
            } catch {
                print("Failed to handle url: \(url), \(error)")
                return .systemAction
            }
        })
        .animation(.bouncy, value: viewMode)
        .inspector(isPresented: $citationHandler.citationSidebarOpen) {
            CitationColumnView(citations: $citationHandler.citations)
        }
        .toolbar {
            if let newChat {
                ToolbarItem(id: "newChat") {
                    Button {
                        newChat()
                    } label: {
                        Label("New Chat", systemSymbol: .squareAndPencil)
                    }
                }
            }
            ToolbarItem(id: "sidebar") {
                Button {
                    citationHandler.citationSidebarOpen.toggle()
                } label: {
                    Label("Toggle Sidebar", systemSymbol: .sidebarRight)
                }
            }
        }
        .task {
            for configuration in providers {
                do {
                    guard let provider = try ProviderFactory.makeInstance(configuration: configuration) else { continue }
                    let models = try await provider.availableModels()

                    // Check this provider for the last used model in this chat. If the chat does not have a last used model, check to see if the user's preferred model is from this provider.
                    if let lastUsedModel = chat.lastUsedModel,
                       let model = models.first(where: { $0.id == lastUsedModel }) {
                        selectedModel = model
                        selectedProvider = configuration
                    } else if !preferredModel.isEmpty, let preferred = models.first(where: {$0.id == preferredModel}) {
                        selectedModel = preferred
                        selectedProvider = configuration
                    }

                    providerDatabase[configuration] = models
                } catch {
                    print("Failed to fetch available models for \(configuration.name): \(error)")
                }
            }
            
            // If no previously used model was found, pick the first available one
            if selectedModel == nil,
                let firstConfig = providerDatabase.keys.first,
                let firstModel = providerDatabase[firstConfig]?.first {
                selectedModel = firstModel
                selectedProvider = firstConfig
            }
        }
        .onChange(of: selectedModel) { _, _ in
            initializeChatInstance()
        }
    }

    // MARK: Chat state
    private func transcript(reader: GeometryProxy) -> some View {
        ScrollView {
            if let chatInstance {
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
        .safeAreaInset(edge: .bottom) {
            if viewMode == .chat {
                searchCluster
            }
        }
    }
    
    // MARK: Startup State
    private func startup() -> some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 5) {
                Image("impel_logo")
                    .resizable()
                    .frame(width: 45, height: 45)
                    .accessibilityLabel("Minna Logo")
                Text("Hey \(NSUserFirstName())!")
                    .font(.system(size: 36, design: .serif))
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            searchCluster
            Spacer()
        }
    }

    private var searchCluster: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    presentModelPicker.toggle()
                } label: {
                    if let selectedModel {
                        ModelName(model: selectedModel)
                    } else {
                        Text("No Model Selected")
                    }
                }
                .popover(isPresented: $presentModelPicker) {
                    ModelSelector(providerDatabase: $providerDatabase, selectedModel: $selectedModel, selectedProvider: $selectedProvider)
                }
                .buttonStyle(.glass)
                
                if chatInstance?.waitingForLoad ?? false {
                    ProgressView {
                        Text("Model Loading")
                    }
                }
            }

            IndexingSearchBar(placeHolder: "Search or Ask for Anything", searchQuery: $chatMessage) {
                submit()
            }
            .disabled(selectedModel == nil || chatInstance == nil || (chatInstance?.waitingForLoad ?? false))
        }
        .frame(maxWidth: 640)
        .padding(.bottom, viewMode == .chat ? 20 : 0)
        .id("search")
        .matchedGeometryEffect(id: "search", in: searchContainerTransitions)
    }

    private func submit() {
        let message = chatMessage
        guard !message.isEmpty else { return }
        chatMessage = ""

        if viewMode == .startup {
            modelContext.insert(chat.file)
            viewMode = .chat // Start animations
        }

        Task {
            do {
                try await chatInstance?.sendMessage(message)

                if chat.file.title == Chat.defaultTitle,
                   let lastMessage = chat.transcript.last,
                   case .response(let response) = lastMessage,
                   case .text(let last)? = response.segments.last {
                    chat.file.title = last.content.makeTitle()
                }
            } catch {
                if chatMessage.isEmpty {
                    chatMessage = message
                }
                print("Failed to send chat: \(error)")
            }
        }
    }

    private func initializeChatInstance() {
        if let model = selectedModel, let config = selectedProvider {
            do {
                // Update the chat so it will open with the model you last used.
                chat.lastUsedModel = model.id
                // If we have already started chatting update the chat in the database. Otherwise, we don't want to insert here or empty chats will be added to the file list.
                if viewMode == .chat {
                    modelContext.insert(chat)
                }
                
                let instance = try ChatInstance(irisDB: try irisContext.database, databaseContext: modelContext, model: model, configuration: config, chat: chat, instructions: AskMinnaInstructions.self)
                
                chatInstance = instance

                Task {
                    do {
                        try await instance.loadModel()
                    } catch {
                        print("Failed to preload model \(error)")
                    }
                }
            } catch {
                print("Failed to get database \(error)")
            }
        } else {
//            if let chatInstance {
//                Task {
//                    do {
//                        try await chatInstance.unloadModel()
//                    } catch {
//                        print("Failed to preload model \(error)")
//                    }
//                }
//            }
            
            chatInstance = nil
        }
    }
}

#Preview {
    @Previewable var controller = IrisDBController(modelContainer: SampleDatabase.shared.modelContainer)
    
    AskMinnaView(chat: Chat.make(in: SampleDatabase.shared.sampleFolders.first!), viewMode: .chat) {
        
    }
    .irisContext(controller.mainContext)
    .modelContext(SampleDatabase.shared.context)
}
