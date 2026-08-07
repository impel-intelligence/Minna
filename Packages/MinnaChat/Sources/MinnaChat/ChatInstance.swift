//
//  ChatInstance.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

import SwiftUI
import AnyLanguageModel
import IrisSearch
import SwiftData
import DatabaseSchema
import ModelManager

@Observable @MainActor
public final class ChatInstance {
    enum ChatError: Error {
        case invalidConfiguration
        case alreadyResponding
        case modelNotLoaded
        case modelFailedToLoad(reason: String?)
    }
    
    let databaseContext: ModelContext
    let irisDB: IrisDB
    let chat: Chat
    
    let model: any ModelManager.Model

    let provider: any ModelProvider
    let languageModel: any LanguageModel
    
    public let session: LanguageModelSession
    let toolObserver: ToolExecutionObserver = ToolExecutionObserver()
    
    public var waitingForResponse: Bool = false
    private var generationTask: Task<Void, any Error>?

    public init(irisDB: IrisDB, databaseContext: ModelContext, model: any ModelManager.Model, configuration: ConfiguredProvider, chat: Chat, instructions: any ModelInstruction, tools: [AvailableTool]) throws {
        self.databaseContext = databaseContext
        self.model = model
        self.irisDB = irisDB
        self.chat = chat
        
        guard let provider = try ProviderFactory.makeInstance(configuration: configuration) else { throw ChatError.invalidConfiguration }
        
        self.provider = provider
        self.languageModel = try provider.getModel(id: model.id)
        
        let tools: [any Tool] = tools.map({$0.getTool(irisDB: irisDB)})
        
        if chat.transcript.isEmpty {
            self.session = LanguageModelSession(model: languageModel, tools: tools, instructions: instructions.getPrompt())
        } else {
            self.session = LanguageModelSession(model: languageModel, tools: tools, transcript: chat.transcript)
        }
        
        session.toolExecutionDelegate = toolObserver
        session.prewarm()
    }
    
    public func sendMessage(_ message: String) async throws {
        guard !session.isResponding, generationTask == nil else {
            throw ChatError.alreadyResponding
        }

        
        guard languageModel.isAvailable else {
            throw ChatError.modelNotLoaded
        }
                
        let generationOptions = provider.generationOptions(model: model)
        
        let task = Task { @MainActor in
            waitingForResponse = true
            defer { waitingForResponse = false }
            
            for try await _ in session.streamResponse(to: Prompt(message), options: generationOptions) {
                waitingForResponse = false
            }
        }
        
        generationTask = task
        defer { generationTask = nil }

        do {
            try await task.value
        } catch where error is CancellationError || Task.isCancelled {
            /* keep partial */
        } catch let urlError as URLError where urlError.code == .cancelled {
            /* keep partial */
        } catch {
//            if let lastMessage = session.transcript.last,
//               lastMessage.plainText == message {
//                session.transcript.dropLast(1)
//            }
            
            throw error
        }

        chat.apply(session.transcript)
        try databaseContext.save()

    }
    
    public func cancel() {
        generationTask?.cancel()
        generationTask = nil
    }
    
    public func clearCache() async {
        if let mlxModel = languageModel as? MLXLanguageModel {
            await mlxModel.removeFromCache()
        }
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
