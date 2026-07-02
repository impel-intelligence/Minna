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


//extension Message {
//    var entry: Transcript.Entry {
//        switch message.owner {
//        case .assistant:
//            entries.append(Transcript.Entry.response(Transcript.Response(assetIDs: <#T##[String]#>, segments: [.text(<#T##Transcript.TextSegment#>)])))
//        case .user:
//            entries.append(Transcript.Entry.prompt(
//                Transcript.Prompt(segments: [
//                    .text(Transcript.TextSegment(content: self))
//                ])
//            ))
//        }
//
//    }
//    
//    var transcriptPrompt: Transcript.Prompt {
//        Transcript.Prompt(segments: [
//            .text(Transcript.TextSegment(content: self))
//        ])
//    }
//}

//extension Array where Element == DatabaseSchema.Message {
//    func createTranscript() -> Transcript {
//        var entries: [Transcript.Entry] = []
//        
//        for message in self.sorted(using: KeyPathComparator(\.createdAt, order: .reverse)) {
//        }
//        
//        return Transcript(entries: entries)
//    }
//}

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
    
    let model: ModelManager.Model

    let provider: any ModelProvider
    let languageModel: any LanguageModel
    
    let session: LanguageModelSession
    let toolObserver: ToolExecutionObserver = ToolExecutionObserver()
    
    public private(set) var streamingResponse: String? = nil
    
    public init(irisDB: IrisDB, databaseContext: ModelContext, model: ModelManager.Model, configuration: ConfiguredProvider, chat: Chat) throws {
        self.databaseContext = databaseContext
        self.model = model
        self.irisDB = irisDB
        self.chat = chat
        
        guard let provider = try ProviderFactory.makeInstance(configuration: configuration) else { throw ChatError.invalidConfiguration }
        
        self.provider = provider
        self.languageModel = provider.getModel(id: model.id)
        
        self.session = LanguageModelSession(model: languageModel, tools: [], transcript: chat.transcript)
        session.toolExecutionDelegate = toolObserver
        session.prewarm()
    }
    
    public func sendMessage(_ message: String) async throws {
        guard !session.isResponding else {
            throw ChatError.alreadyResponding
        }
        
        guard languageModel.isAvailable else {
            throw ChatError.modelNotLoaded
        }
        
        // Start the stream response
        let stream = session.streamResponse(to: Prompt(message))
        // Update transcript because the user message was just inserted
        chat.apply(session.transcript)

        // Update the streamingResponse as new text comes from the stream.
        for try await chunk in stream {
            streamingResponse = chunk.content
        }
        
        streamingResponse = nil
        chat.apply(session.transcript)
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
