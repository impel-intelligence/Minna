//
//  ProviderToAssetMap.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import ModelManager

protocol AssetProvider {
    static var marketingName: String { get }
    static var image: ImageResource { get }
    static var background: Color { get }
}

extension AnthropicProvider: AssetProvider {
    static var marketingName: String { "Claude" }
    static var image: ImageResource { .Providers.Claude.logo }
    static var background: Color { .Providers.Claude.background }
}

extension AppleProvider: AssetProvider {
    static var marketingName: String { "Apple Intelligence" }
    static var image: ImageResource { .Providers.Apple.logo }
    static var background: Color { .primary }
}

extension OllamaProvider: AssetProvider {
    static var marketingName: String { "Ollama" }
    static var image: ImageResource { .Providers.Ollama.logo }
    static var background: Color { .primary }
}

extension GeminiProvider: AssetProvider {
    static var marketingName: String { "Gemini" }
    static var image: ImageResource { .Providers.Gemini.logo }
    static var background: Color { .primary }
}

extension OpenAIProvider: AssetProvider {
    static var marketingName: String { "OpenAI" }
    static var image: ImageResource { .Providers.OpenAI.logo }
    static var background: Color { .primary }
}

extension MLXProvider: AssetProvider {
    static var marketingName: String { "MLX" }
    static var image: ImageResource { .Providers.MLX.logo }
    static var background: Color { .primary }
}
