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
                Log.logger.error("Failed to fetch available models", error: error, metadata: ["configuration": "\(configuration.name)"])
            }
        }
        
        // If no previously used model was found, pick the first available one
        if selectedModel == nil,
            let firstConfig = providerDatabase.keys.first,
            let firstModel = providerDatabase[firstConfig]?.first {
            selectedModel = firstModel
            selectedProvider = firstConfig
        }
        
        initializeChatInstance(modelContext: modelContext, irisContext: irisContext)
    }
    
    private func initializeChatInstance(modelContext: ModelContext, irisContext: IrisContext) {
        if let model = selectedModel, let config = selectedProvider {
            // TODO: Propagate this catch all the way out to UI
            do {
                // Update the chat so it will open with the model you last used.
                chat.lastUsedModel = model.id
                
                chatInstance = try ChatInstance(irisDB: try irisContext.database, databaseContext: modelContext, model: model, configuration: config, chat: chat, instructions: instructions, tools: availableTools)
            } catch {
                Log.logger.error("Failed to create chat instance.", error: error)
            }
        } else {
            chatInstance = nil
        }
    }
}
