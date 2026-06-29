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

@Observable @MainActor
public final class ChatInstance {
    let model: MLXLanguageModel
    let session: LanguageModelSession
    let toolObserver: ToolExecutionObserver = ToolExecutionObserver()
    
    public var currentGeneration: String = ""
    
    public init(irisDB: IrisDB) {
        model = MLXLanguageModel(modelId: "mlx-community/Qwen3-0.6B-4bit")
        session = LanguageModelSession(model: model, tools: [])
        session.toolExecutionDelegate = toolObserver
        session.prewarm()
    }
    
    public func sendMessage(_ message: String) async throws {
        guard !session.isResponding else { return }
        
        for try await chunk in session.streamResponse(to: Prompt(message)) {
            currentGeneration = chunk.content
            print("received chunk \(chunk.content)")
        }
    }
}
