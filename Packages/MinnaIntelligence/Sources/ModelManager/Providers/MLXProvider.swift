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
        
        if let model = model as? DownloadedModel {
            generationOptions.temperature = model.configuration.temperature

            generationOptions[custom: MLXLanguageModel.self] = .init(
                kvCache: .default,
                userInputProcessing: nil,
                additionalContext: [ "enable_thinking": false],
                topP: model.configuration.topP.map(Float.init),
                topK: model.configuration.topK.map(Int.init),
                minP: model.configuration.minP.map(Float.init),
                presencePenalty: model.configuration.presencePenalty.map(Float.init),
                repetitionPenalty: model.configuration.repetitionPenalty.map(Float.init)
            )

        }
       
        return generationOptions
    }
}
