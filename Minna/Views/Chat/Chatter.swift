//
//  Chatter.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//

import SwiftUI
import DatabaseSchema
import OrderedCollections
import ModelManager
import MinnaChat
import SwiftData
import Logging


@Observable
final class Chatter {
    var selectedProvider: ConfiguredProvider?
    var selectedModel: Model?
    
    var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]> = [:]

    var chatInstance: ChatInstance?
    var chatMessage: String = ""

    var preferredModel: String
    let chat: Chat
    let instructions: any ModelInstruction
    let availableTools: [AvailableTool]
    
    init(chat: Chat, instructions: any ModelInstruction, availableTools: [AvailableTool]) {
        self.chat = chat
        self.instructions = instructions
        self.availableTools = availableTools
        self.preferredModel = UserDefaults.standard.string(forKey: AppStorageKeys.preferredModel) ?? ""
    }
    
    func submit() async throws {
        let message = chatMessage
        guard !message.isEmpty else { return }
        chatMessage = ""

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
            
            throw error
        }
    }
        
    func gatherProviders(modelContext: ModelContext, irisContext: IrisContext) async throws {
        let providers = try modelContext.fetch(FetchDescriptor<ConfiguredProvider>())

        let lastUsedModel = chat.lastUsedModel
        let sorted = providers.sorted { a, _ in
            guard let lastUsedModel else { return false }
            return a.cachedModelIDs.contains(lastUsedModel)
        }

        for configuration in sorted {
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

                configuration.cachedModelIDs = Set(models.map({$0.id}))
                providerDatabase[configuration] = models
                
                // Once we find a suitable model load it so the view can get rendering.
                if chatInstance == nil, let selectedModel, let selectedProvider {
                    initializeChatInstance(modelContext: modelContext, irisContext: irisContext, provider: selectedProvider, model: selectedModel)
                }
            } catch {
                Log.logger.error("Failed to fetch available models", error: error, metadata: ["configuration": "\(configuration.name)"])
            }
        }
        
        try modelContext.save()
        
        // If no previously used model was found, pick the first available one
        if chatInstance == nil,
            let firstConfig = providerDatabase.keys.first,
            let firstModel = providerDatabase[firstConfig]?.first {
            selectedModel = firstModel
            selectedProvider = firstConfig
            initializeChatInstance(modelContext: modelContext, irisContext: irisContext, provider: firstConfig, model: firstModel)
        }
    }
    
    private func loadCachedProvider(providers: [ConfiguredProvider], modelContext: ModelContext, irisContext: IrisContext) async throws -> (any Model, ConfiguredProvider)? {
        guard let lastUsedModel = chat.lastUsedModel else { return nil }
        guard let cachedProvider = providers.first(where: {$0.cachedModelIDs.contains(lastUsedModel)}) else { return nil }
        
        guard let provider = try ProviderFactory.makeInstance(configuration: cachedProvider) else { return nil }
        let models = try await provider.availableModels()
        providerDatabase[cachedProvider] = models

        guard let model = models.first(where: { $0.id == lastUsedModel }) else { return nil }        
        
        return (model, cachedProvider)
    }

    private func initializeChatInstance(modelContext: ModelContext, irisContext: IrisContext, provider: ConfiguredProvider, model: (any Model)) {
        do {
            // Update the chat so it will open with the model you last used.
            chat.lastUsedModel = model.id
            
            chatInstance = try ChatInstance(irisDB: try irisContext.database, databaseContext: modelContext, model: model, configuration: provider, chat: chat, instructions: instructions, tools: availableTools)
        } catch {
            Log.logger.error("Failed to create chat instance.", error: error)
        }
    }
}
