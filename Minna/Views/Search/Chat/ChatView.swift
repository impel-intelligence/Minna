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
    @Environment(ModelDownloader.self) var modelDownloader
        
    @Query(sort: \ConfiguredProvider.name) private var providers: [ConfiguredProvider]
    @State var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]> = [:]
    @State var selectedProvider: ConfiguredProvider?
    @State var selectedModel: Model?
    
    @State var chatInstance: ChatInstance?
    @State var chatMessage: String = ""

    @State var presentModelPicker: Bool = false

    @State var chat: Chat = Chat()

    var body: some View {
        GeometryReader { reader in
            ScrollView {
                ForEach(chat.transcript) { entry in
                    switch entry {
                    case .instructions:
                        EmptyView()
                        //            MyInstructionsView(instructions)
                    case .prompt(let prompt):
                        EmptyView()
                        UserMessage(prompt: prompt, proxy: reader)
                        //            MyPromptView(prompt)
                    case .toolCalls(let toolCalls):
                        EmptyView()
                        //            MyToolCallsView(toolCalls)
                    case .toolOutput(let toolOutput):
                        EmptyView()
                        //            MyToolOutputView(toolOutput)
                    case .response(let response):
                        AssistantMessage(response: response, proxy: reader)
                        //            MyResponseView(response)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                if let streamingResponse = chatInstance?.streamingResponse {
                    AssistantMessage(response: Transcript.Response.tempResponse(content: streamingResponse), proxy: reader)
                }
            }
            .padding()
            .defaultScrollAnchor(.bottom)
            .safeAreaInset(edge: .bottom) {
                chatBox
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
            }
            Spacer()
        }
        .padding([.bottom], 20)
    }
    
    func initializeChatInstance() {
        if let model = selectedModel, let config = selectedProvider {
            do {
                chatInstance = try ChatInstance(irisDB: try irisContext.database, databaseContext: modelContext, model: model, configuration: config, chat: chat)
            } catch {
                print("Failed to get database \(error)")
            }
        } else {
            chatInstance = nil
        }
    }
}

#Preview {
    @Previewable @State var selectedModel: Model?
    @Previewable @State var selectedProvider: ConfiguredProvider?

    @Previewable @State var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]> = [
        ConfiguredProvider(name: "Apple Intelligence", providerID: "apple"): [
            Model(id: "foundation", displayName: "Apple Foundation", provider: AppleProvider.self)
        ]
    ]
    
    ModelSelector(providerDatabase: $providerDatabase, selectedModel: $selectedModel, selectedProvider: $selectedProvider)
        .modelContext(SampleDatabase.shared.context)
}

#Preview {
    ChatView()
        .modelContext(SampleDatabase.shared.context)
        .environment(ModelDownloader())
}
