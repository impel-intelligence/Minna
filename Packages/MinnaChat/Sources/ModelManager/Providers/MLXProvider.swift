//
//  MLXProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/5/26.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema
import HuggingFace

@available(macOS 26.0, *)
public struct MLXProvider: ModelProvider, Sendable {
    public static let id: String = "mlx"
    public static let editable: Bool = false
    public static let fields: [ProviderField] = []
    
    public static let hub: HubClient = HubClient(cache: HubCache.minnaCache)
    
    public init() { }
    
    public static func make(from values: [String: String]) throws -> MLXProvider {
        return MLXProvider()
    }
    
    public static func make(from configuration: ConfiguredProvider) throws -> MLXProvider {
        return MLXProvider()
    }
    
    public func getModel(id: String) throws -> any AnyLanguageModel.LanguageModel {
        let model = try LocalModelRepo.shared.getModel(id: id)
        return MLXLanguageModel(modelId: id, hub: MLXProvider.hub, directory: model.directory)
    }
    
    public func availableModels() async throws -> [any Model] {
        return try LocalModelRepo.shared.availableModels()
    }
    
    public func generationOptions(model: any Model) -> AnyLanguageModel.GenerationOptions {
        var generationOptions = GenerationOptions()
        generationOptions.temperature = 1.0
       
        // TODO: Make this less specific to qwen 9b
        // temperature=1.0, top_p=0.95, top_k=20, min_p=0.0, presence_penalty=1.5, repetition_penalty=1.0
        generationOptions[custom: MLXLanguageModel.self] = .init(
            kvCache: .default,
            userInputProcessing: nil,
            additionalContext: [ "enable_thinking": false ],
            topP: 0.95,
            topK: 20,
            minP: 0.0,
            presencePenalty: 1.5,
            repetitionPenalty: 1.0
        )

        return GenerationOptions()
    }
}
