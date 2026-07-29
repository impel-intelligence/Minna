//
//  ProviderFactory.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//

import DatabaseSchema

public struct ProviderFactory {
    public static func makeType(id: String) -> (any ModelProvider.Type)? {
        if #available(macOS 26.0, *), id == AppleProvider.id {
            return AppleProvider.self
        }
        
        switch id {
        case AnthropicProvider.id:
            return AnthropicProvider.self
        case OllamaProvider.id:
            return OllamaProvider.self
        default:
            return nil
        }
    }
    
    public static func makeInstance(configuration: ConfiguredProvider) throws -> (any ModelProvider)? {
        if #available(macOS 26.0, *), configuration.providerID == AppleProvider.id {
            return AppleProvider()
        }

        switch configuration.providerID {
        case AnthropicProvider.id:
            return try AnthropicProvider.make(from: configuration)
        case OllamaProvider.id:
            return try OllamaProvider.make(from: configuration)
        default:
            return nil
        }
    }
}
