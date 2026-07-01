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

struct ChatView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(ModelDownloader.self) var modelDownloader
    
    @Query(sort: \Message.createdAt) private var messages: [Message]
    
    @State var selectedModel: ModelManager.Model?
    
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
                        case .user:
                            UserMessage(message: message, proxy: reader)
                        }
                    }
                    if let generatingMessage = chatInstance?.generatingMessage {
                        AssistantMessage(message: generatingMessage, proxy: reader)
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)
            .safeAreaInset(edge: .bottom) {
                chatBox
            }
        }
        .task {
            do {
                chatInstance = ChatInstance(irisDB: try irisContext.database, databaseContext: modelContext)
            } catch {
                print("Failed to get database \(error)")
            }
        }
    }
    
    @State var presentModelPicker: Bool = false
    
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
                    ModelSelector(selectedModel: $selectedModel)
                }

                SearchBar(placeHolder: "Search or Ask for Anything", searchQuery: $chatMessage) {
                    Task {
                        let tmpMessage = chatMessage
                        chatMessage = ""
                        
                        let userMessage = Message(chat: chat, owner: .user, textContent: tmpMessage)
                        modelContext.insert(userMessage)
                        
//                        do {
////                            try await chatInstance?.sendMessage(userMessage.textContent, in: chat)
//                        } catch {
//                            if chatMessage.isEmpty {
//                                chatMessage = tmpMessage
//                                modelContext.delete(userMessage)
//                            }
//                            print("Failed to send chat: \(error)")
//                        }
                    }
                }
                .disabled(selectedModel == nil)
            }
            Spacer()
        }
        .padding([.bottom], 20)
    }
}

struct ModelSelector: View {
    @Environment(\.openModernSettings) var openSettings
    @Query(sort: \ConfiguredProvider.name) private var providers: [ConfiguredProvider]

    @Binding var selectedModel: Model?
    
    @State var providerDatabase: [ConfiguredProvider: [Model]] = [:]

    var body: some View {
        VStack {
            header
            List {
                ForEach(Array(providerDatabase.keys)) { provider in
                    Section(provider.name) {
                        ForEach(providerDatabase[provider] ?? []) { model in
                            cellFor(model: model )
                        }
                    }
                    .listRowSeparator(.hidden, edges: .all)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .frame(width: 350, height: 450)
        .task {
            for configuration in providers {
                do {
                    guard let provider = try ProviderFactory.makeInstance(configuration: configuration) else { continue }
                    let models = try await provider.availableModels()
                    providerDatabase[configuration] = models
                } catch {
                    print("Failed to fetch available models for \(configuration.name): \(error)")
                }
            }
        }
    }
    
    var header: some View {
        HStack {
            Text("Available Models")
                .font(.title3)
                .bold()
                .lineLimit(1)
            HStack(alignment: .center) {
                Text("\(providerDatabase.flatMap({$0.value}).count)")
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 10, weight: .regular, design: .default))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.pillBackground)
            .clipShape(.rect(cornerRadius: 4))
            Spacer()
            Button {
                openSettings()
            } label: {
                Label("Get More", systemSymbol: .plus)
            }
        }
        .padding(.top, 10)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func cellFor(model: Model) -> some View {
        Button {
            selectedModel = model
        } label: {
            HStack {
                Image(systemSymbol: .checkmark)
                    .fontWeight(.semibold)
                    .symbolEffect(.bounce, value: selectedModel == model)
                    .opacity(selectedModel == model ? 1 : 0)
                    .accessibilityLabel("Model Selected", isEnabled: selectedModel == model)
                
                ModelName(model: model)
            }
        }
        .buttonStyle(.plain)

    }
}

struct ModelName: View {
    let model: Model
    
    var body: some View {
        if let assetProvider = model.provider as? AssetProvider.Type {
            Image(assetProvider.image)
                .resizable()
                .frame(width: 15, height: 15)
                .accessibilityLabel("\(assetProvider.marketingName)'s logo")
        }
        
        Text(model.displayName)
    }
}

#Preview {
    @Previewable @State var selectedModel: Model?
    
    ModelSelector(selectedModel: $selectedModel)
        .modelContext(SampleDatabase.shared.context)
}

#Preview {
    ChatView()
        .modelContext(SampleDatabase.shared.context)
        .environment(ModelDownloader())
}
