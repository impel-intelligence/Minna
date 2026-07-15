//
//  LocalProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/14/26.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema
import HuggingFace

public struct LocalProvider: ModelProvider, Sendable {
    public static let id: String = "local"
    public static let editable: Bool = false
    public static let fields: [ProviderField] = []
    
    let downloader: HuggingFaceDownloader = HuggingFaceDownloader()
    
    public init() { }
    
    public static func make(from values: [String: String]) throws -> LocalProvider {
        return LocalProvider()
    }
    
    public static func make(from configuration: ConfiguredProvider) throws -> LocalProvider {
        return LocalProvider()
    }
    
    public func getModel(id: String) -> any AnyLanguageModel.LanguageModel {
        return MLXLanguageModel(modelId: id, hub: downloader.client, directory: downloader.directoryFor(id: id))
    }
    
    public func availableModels() async throws -> [Model] {
        return await downloader.availableModels().map { id in
            Model(id: id, displayName: id, provider: LocalProvider.self)
        }
    }
}
