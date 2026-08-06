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
    
    public func getModel(id: String) -> any AnyLanguageModel.LanguageModel {
        let model = LocalModelRepo.shared.getModel(id: id)
        return MLXLanguageModel(modelId: id, hub: MLXProvider.hub, directory: model.directory)
    }
    
    public func availableModels() async throws -> [any Model] {
        return LocalModelRepo.shared.availableModels()
    }
    
    public func generationOptions(model: any Model) -> AnyLanguageModel.GenerationOptions {
        return GenerationOptions()
    }
}
