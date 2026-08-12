//
//  ProviderToAssetMap.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-11

import SwiftUI
import ModelManager

protocol AssetProvider {
    static var marketingName: String { get }
    static var image: ImageResource { get }
    static var background: Color { get }
    
    static var apiKeySupport: URL? { get }
}

extension AnthropicProvider: AssetProvider {
    static var marketingName: String = "Claude"
    static var image: ImageResource = .Providers.Claude.logo
    static var background: Color = .Providers.Claude.background
    static var apiKeySupport: URL? = URL(string: "https://platform.claude.com/docs/en/get-api-key")
}

extension AppleProvider: AssetProvider {
    static var marketingName: String = "Apple Intelligence"
    static var image: ImageResource = .Providers.Apple.logo
    static var background: Color = Color(nsColor: .windowBackgroundColor)
    static var apiKeySupport: URL? = URL(string: "https://support.apple.com/en-us/121115")
}

extension OllamaProvider: AssetProvider {
    static var marketingName: String = "Ollama"
    static var image: ImageResource = .Providers.Ollama.logo
    static var background: Color = Color(nsColor: .windowBackgroundColor)
    static var apiKeySupport: URL? = URL(string: "https://docs.ollama.com/quickstart")
}

extension GeminiProvider: AssetProvider {
    static var marketingName: String = "Gemini"
    static var image: ImageResource = .Providers.Gemini.logo
    static var background: Color = Color(nsColor: .windowBackgroundColor)
    static var apiKeySupport: URL? = URL(string: "https://ai.google.dev/gemini-api/docs/api-key")
}

extension OpenAIProvider: AssetProvider {
    static var marketingName: String = "OpenAI"
    static var image: ImageResource = .Providers.OpenAI.logo
    static var background: Color = Color(nsColor: .windowBackgroundColor)
    static var apiKeySupport: URL? = URL(string: "https://help.openai.com/en/articles/4936850-where-do-i-find-my-openai-api-key")
}

extension MLXProvider: AssetProvider {
    static var marketingName: String = "MLX"
    static var image: ImageResource = .Providers.MLX.logo
    static var background: Color = Color(nsColor: .windowBackgroundColor)
    static var apiKeySupport: URL? = nil
}
