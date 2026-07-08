//
//  ChatView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-07-06.
//  Merged compose + chat into AskMinnaView by Claude Opus 4.8 (Anthropic) on 2026-07-08.
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

/// The unified "Ask Minna" screen. It renders a single search bar whose position
/// is driven by ``hasStarted``: centered under the logo while composing, pinned to
/// the bottom once a conversation is under way. Because the bar is the same view
/// node in both states, toggling `hasStarted` inside an animation makes it glide
/// from center to bottom.
///
/// The same view serves both the compose flow (Search tab, `hasStarted == false`,
/// with a `newChat` reset closure) and existing chats opened from a folder
/// (`hasStarted == true`, no `newChat`).
///
/// - Authored by: Claude Opus 4.8 (Anthropic)
struct AskMinnaView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext

    /// The chat this view drives. Stable for the lifetime of the view's identity;
    /// callers swap chats by changing the view's `.id`.
    let chat: Chat

    /// Invoked by the New Chat toolbar button. `nil` hides the button (e.g. when
    /// viewing an existing chat pushed from a folder).
    var newChat: (() -> Void)?

    /// Layout phase. `false` shows the centered compose state; `true` shows the
    /// transcript with the bar pinned to the bottom.
    @State private var hasStarted: Bool

    @State private var citationHandler: CitationHandler = CitationHandler()

    @Query(sort: \ConfiguredProvider.name) private var providers: [ConfiguredProvider]
    @State private var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]> = [:]
    @State private var selectedProvider: ConfiguredProvider?
    @State private var selectedModel: Model?

    @State private var chatInstance: ChatInstance?
    @State private var chatMessage: String = ""

    @State private var presentModelPicker: Bool = false

    init(chat: Chat, hasStarted: Bool, newChat: (() -> Void)? = nil) {
        self.chat = chat
        self.newChat = newChat
        _hasStarted = State(initialValue: hasStarted)
    }

    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 16) {
                if !hasStarted {
                    Spacer(minLength: 0)
                    composeHeader
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    transcript(reader: reader)
                        .transition(.opacity)
                }

                searchCluster

                if !hasStarted {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
        }
        .theme(chat.theme)
        .navigationTitle(chat.title())
        .environment(citationHandler)
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == "cite", let docID = url.host() else {
                return .systemAction
            }
            let title = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "title" })?.value
            // TODO: navigate to / preview the cited document using docID (and title).
            print(docID, title as Any)
            return .handled
        })
        .animation(.bouncy, value: hasStarted)
        .animation(.bouncy, value: chat.transcript)
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
                    .accessibilityIdentifier("askMinna.newChat")
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

                    if let lastUsedModel = chat.lastUsedModel,
                       let model = models.first(where: { $0.id == lastUsedModel }) {
                        selectedModel = model
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

    // MARK: Compose state

    private var composeHeader: some View {
        VStack(spacing: 5) {
            Image("impel_logo")
                .resizable()
                .frame(width: 45, height: 45)
                .accessibilityLabel("Minna Logo")
            Text("Hey \(NSUserFirstName())!")
                .font(.system(size: 36, design: .serif))
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
                }
                .padding(.horizontal)
            } else {
                Text("No Model Selected")
            }
        }
        .defaultScrollAnchor(.bottom)
    }

    // MARK: Shared search bar (stable node across states)
    private var searchCluster: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            IndexingSearchBar(placeHolder: "Search or Ask for Anything", searchQuery: $chatMessage) {
                submit()
            }
            .disabled(selectedModel == nil || chatInstance == nil)
        }
        .frame(maxWidth: 640)
        .padding(.bottom, hasStarted ? 20 : 0)
    }

    private func submit() {
        let message = chatMessage
        guard !message.isEmpty else { return }
        chatMessage = ""

        if !hasStarted {
            modelContext.insert(chat.file)
            hasStarted = true // Start slide animation
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
                if hasStarted {
                    modelContext.insert(chat)
                }
                
                chatInstance = try ChatInstance(irisDB: try irisContext.database, databaseContext: modelContext, model: model, configuration: config, chat: chat, instructions: AskMinnaInstructions.self)
            } catch {
                print("Failed to get database \(error)")
            }
        } else {
            chatInstance = nil
        }
    }
}

#Preview {
    AskMinnaView(chat: Chat.make(in: SampleDatabase.shared.sampleFolders.first!), hasStarted: false)
        .modelContext(SampleDatabase.shared.context)
}
