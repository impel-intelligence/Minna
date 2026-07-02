//
//  AnthropicProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-07-01.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema

public struct AnthropicProvider: ModelProvider, Sendable {
    let baseURL: URL
    let apiKey: String
    
    public static let id: String = "claude"
    public static let editable: Bool = true

    public static let fields: [ProviderField] = [
        ProviderField(
            key: "apiKey",
            name: "API Key",
            kind: .secure,
            placeholder: "sk-ant-..."
        ),
        ProviderField(
            key: "baseURL",
            name: "Base URL",
            kind: .text,
            placeholder: AnthropicLanguageModel.defaultBaseURL.absoluteString,
            isAdvanced: true,
            defaultValue: AnthropicLanguageModel.defaultBaseURL.absoluteString
        )
    ]

    public init(baseURL: URL = AnthropicLanguageModel.defaultBaseURL , apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    /// Builds an `AnthropicProvider` from collected form input.
    ///
    /// - Parameter values: Field input keyed by ``ProviderField/key``.
    /// - Returns: A configured provider.
    /// - Throws: ``ProviderConfigurationError`` when the API key is missing or the base URL is malformed.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public static func make(from values: [String: String]) throws -> AnthropicProvider {
        guard let apiKey = values["apiKey"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw ProviderConfigurationError.missingField("API Key")
        }

        let baseURL: URL
        if let raw = values["baseURL"]?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            guard let parsed = URL(string: raw) else {
                throw ProviderConfigurationError.invalidValue(field: "Base URL", value: raw)
            }
            baseURL = parsed
        } else {
            baseURL = AnthropicLanguageModel.defaultBaseURL
        }

        return AnthropicProvider(baseURL: baseURL, apiKey: apiKey)
    }
    
    public static func make(from configuration: ConfiguredProvider) throws -> AnthropicProvider {
        guard let apiKey = configuration.getConfigurationValue(for: "apiKey") else {
            throw ProviderConfigurationError.missingField("API Key")
        }
        
        guard let raw = configuration.getConfigurationValue(for: "baseURL") else {
            throw ProviderConfigurationError.missingField("Base URL")
        }
        
        guard let parsed = URL(string: raw) else {
            throw ProviderConfigurationError.invalidValue(field: "Base URL", value: raw)
        }
        
        return AnthropicProvider(baseURL: parsed, apiKey: apiKey)
    }
    
    public func getModel(id: String) -> any AnyLanguageModel.LanguageModel {
        return AnthropicLanguageModel(baseURL: baseURL, apiKey: apiKey, model: id)
    }
    
    /// Fetches the list of model identifiers available from the Anthropic API.
    ///
    /// - Returns: The `id` of every model returned by the endpoint.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public func availableModels() async throws -> [Model] {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/models"))
        request.httpMethod = "GET"
        request.setValue(AnthropicLanguageModel.defaultAPIVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let modelList = try JSONDecoder().decode(AnthropicModelList.self, from: data)
        return modelList.data.map { item in
            Model(id: item.id, displayName: item.displayName ?? item.id, provider: AnthropicProvider.self)
        }
    }
}

/// The response payload returned by Anthropic's `GET /v1/models` endpoint.
///
/// - Authored by: Claude Opus 4.8 (Anthropic)
fileprivate struct AnthropicModelList: Decodable {
    struct Model: Decodable {
        let id: String
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
        }
    }

    let data: [Model]
}
