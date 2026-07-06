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
import ModernSettingsWindow
import OrderedCollections
import AnyLanguageModel

struct ChatView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
//    @Environment(ModelDownloader.self) var modelDownloader
    
    @State var citationHandler: CitationHandler = CitationHandler()
        
    @Query(sort: \ConfiguredProvider.name) private var providers: [ConfiguredProvider]
    @State var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]> = [:]
    @State var selectedProvider: ConfiguredProvider?
    @State var selectedModel: Model?
    
    @State var chatInstance: ChatInstance?
    @State var chatMessage: String = "Search my database for displays and make a summary."

    @State var presentModelPicker: Bool = false

    @State var chat: Chat = Chat()

    var body: some View {
        GeometryReader { reader in
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
                                ToolCallsView(toolCalls: toolCalls, theme: .azure)
                            case .toolOutput(let toolOutput):
                                ToolOutputView(output: toolOutput, theme: .azure)
                            case .response(let response):
                                AssistantMessage(response: response, proxy: reader)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        if let streamingResponse = chatInstance.streamingResponse {
                            AssistantMessage(response: Transcript.Response.tempResponse(content: streamingResponse), proxy: reader)
                        }
                    }                                                       
                    .padding(.horizontal)
                } else {
                    Text("No Model Selected")
                }
            }
            .defaultScrollAnchor(.bottom)
            .safeAreaInset(edge: .bottom) {
                chatBox
            }
        }
        .environment(citationHandler)
        .environment(\.openURL, OpenURLAction { url in
            print(url)
            guard url.scheme == "cite", let docID = url.host() else {
                return .systemAction
            }
            let title = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "title" })?.value
            // TODO: navigate to / preview the cited document using docID (and title).
            print(docID, title)
            return .handled
        })
        .inspector(isPresented: $citationHandler.citationSidebarOpen) {
            CitationColumnView(citations: $citationHandler.citations)
        }
        .toolbar {
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
                    
                    // TODO: Remember the user's model selection
                    // Set the selected model to the first available.
                    if selectedModel == nil, let first = models.first {
                        selectedModel = first
                        selectedProvider = configuration
                    }
                    
                    providerDatabase[configuration] = models
                } catch {
                    print("Failed to fetch available models for \(configuration.name): \(error)")
                }
            }
        }
        .onChange(of: selectedModel) { _, _ in
            initializeChatInstance()
        }
    }

    var chatBox: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Image(.impelLogo)
                .resizable()
                .frame(width: 36, height: 36)
                .accessibilityLabel("Minna Logo")
            VStack(alignment: .leading) {
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

                SearchBar(placeHolder: "Search or Ask for Anything", searchQuery: $chatMessage) {
                    Task {
                        let tmpMessage = chatMessage
                        chatMessage = ""
                        
                        do {
                            try await chatInstance?.sendMessage(tmpMessage)
                        } catch {
                            if chatMessage.isEmpty {
                                chatMessage = tmpMessage
                            }
                            print("Failed to send chat: \(error)")
                        }
                    }
                }
                .disabled(selectedModel == nil || chatInstance == nil)
                
                if let progress = irisContext.indexingProgress, progress.isIndexing {
                    HStack {
                        Text("Indexing...")
                        ProgressView(value: progress.fractionCompleted)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 450)
                }
            }
            Spacer()
        }
        .padding([.bottom], 20)
    }
    
    func initializeChatInstance() {
        if let model = selectedModel, let config = selectedProvider {
            do {
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
    ChatView()
        .modelContext(SampleDatabase.shared.context)
//        .environment(ModelDownloader())
}
