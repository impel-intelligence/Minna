//
//  AppleProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema

@available(macOS 26.0, *)
public struct AppleProvider: ModelProvider, Sendable {
    public static let id: String = "apple"
    public static let editable: Bool = false
    public static let fields: [ProviderField] = []
    
    public init() { }
    
    public static func make(from values: [String: String]) throws -> AppleProvider {
        return AppleProvider()
    }
    
    public static func make(from configuration: ConfiguredProvider) throws -> AppleProvider {
        return AppleProvider()
    }
    
    public func getModel(id: String) -> any AnyLanguageModel.LanguageModel {
        return SystemLanguageModel()
    }
    
    public func availableModels() async throws -> [Model] {
        return [
            Model(id: "foundation", displayName: "Apple Foundation Model", provider: AppleProvider.self)
        ]
    }
}
