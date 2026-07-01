//
//  ChatInstance.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

import SwiftUI
import AnyLanguageModel
import IrisSearch
import Hub
import SwiftData
import DatabaseSchema
import ModelManager
import HuggingFace

@Observable @MainActor
public final class ChatInstance {
    enum ChatError: Error {
        case invalidConfiguration
        case alreadyResponding
        case modelNotLoaded
        case modelFailedToLoad(reason: String?)
    }
        
    let databaseContext: ModelContext
    
    let model: ModelManager.Model

    let provider: any ModelProvider
    let languageModel: any LanguageModel
    
    let session: LanguageModelSession
    let toolObserver: ToolExecutionObserver = ToolExecutionObserver()
    
    public var generatingMessage: DatabaseSchema.Message? = nil
    
    public init(irisDB: IrisDB, databaseContext: ModelContext, model: ModelManager.Model, configuration: ConfiguredProvider) throws {
        self.databaseContext = databaseContext
        self.model = model
        
        guard let provider = try ProviderFactory.makeInstance(configuration: configuration) else { throw ChatError.invalidConfiguration }
        
        self.provider = provider
        self.languageModel = provider.getModel(id: model.id)
        
        self.session = LanguageModelSession(model: languageModel, tools: [])
        session.toolExecutionDelegate = toolObserver
        session.prewarm()
    }
    
    public func sendMessage(_ message: String, in chat: Chat) async throws {
        guard !session.isResponding else {
            throw ChatError.alreadyResponding
        }
        
        guard languageModel.isAvailable else {
            throw ChatError.modelNotLoaded
        }
        
        generatingMessage = DatabaseSchema.Message(chat: chat, owner: .assistant, textContent: "")
        
        for try await chunk in session.streamResponse(to: Prompt(message)) {
            generatingMessage?.textContent = chunk.content
        }
        
        guard let message = generatingMessage else { return }
        generatingMessage = nil
        databaseContext.insert(message)
    }
        
//    /// Downloads the model weights with progress, then loads them into memory.
//    /// Safe to call repeatedly — already-cached files are skipped.
//    public func prepareModel() async {
//        if case .ready = downloader.phase { return }
//        do {
//            // 1. Download with progress. Writes to the same Hub cache the
//            //    MLXLanguageModel will later read from, so no double download.
//            _ = try await downloadModel(
//                hub: hub,
//                configuration: ModelConfiguration(id: modelID)
//            ) { progress in
//                Task { @MainActor in
//                    self.downloader.phase = .downloading(
//                        fraction: progress.fractionCompleted,
//                        bytesPerSecond: nil
//                    )
//                }
//            }
//            
//            // 2. Weights are on disk — warm MLX into memory.
//            downloader.phase = .loading
//            session.prewarm()
//            downloader.phase = .ready
//        } catch {
//            print("Failed \(error)")
//            downloader.phase = .failed(String(describing: error))
//        }
//    }
}
