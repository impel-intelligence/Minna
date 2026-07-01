//
//  ProviderFactory.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//

public struct ProviderFactory {
    public static func make(id: String) -> AnthropicProvider.Type? {
        switch id {
        case AnthropicProvider.id:
            return AnthropicProvider.self
        default:
            return nil
        }
    }
}
