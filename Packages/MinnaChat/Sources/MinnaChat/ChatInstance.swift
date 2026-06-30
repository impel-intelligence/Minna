//
//  ChatInstance.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-06-29
//

import SwiftUI
import AnyLanguageModel
import IrisSearch
import Hub
import MLXLMCommon


@Observable @MainActor
public final class ChatInstance {
    enum ChatError: Error {
        case modelNotLoaded
        case modelFailedToLoad(reason: String?)
    }
    
//    let hub = HubApi()
//    public let downloader = ModelDownloadProgress()

    let modelID: String
    let model: MLXLanguageModel
    let session: LanguageModelSession
    let toolObserver: ToolExecutionObserver = ToolExecutionObserver()
    
    public var currentGeneration: String = ""
    
    public init(irisDB: IrisDB, modelID: String = "mlx-community/Qwen3.5-4B-4bit") {
        self.modelID = modelID
        model = MLXLanguageModel(modelId: modelID)
        session = LanguageModelSession(model: model, tools: [])
        session.toolExecutionDelegate = toolObserver
        session.prewarm()
    }
    
    public func sendMessage(_ message: String) async throws {
        guard !session.isResponding else { return }
        
        // Check if the model is available. If it is not, throw an error
        switch model.availability {
        case .unavailable(let unavailableReason):
            switch unavailableReason {
            case .notLoaded:
                throw ChatError.modelNotLoaded
            case .failedToLoad(let string):
                throw ChatError.modelFailedToLoad(reason: string)
            }
        default: break
        }
        
        for try await chunk in session.streamResponse(to: Prompt(message)) {
            currentGeneration = chunk.content
            print("received chunk \(chunk.content)")
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
