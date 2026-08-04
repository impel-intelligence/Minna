//
//  GeminiProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/3/26.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema

public struct GeminiProvider: ModelProvider, Sendable {
    let baseURL: URL
    let apiKey: String
    let apiVersion: String
    
    public static let id: String = "gemini"
    public static let editable: Bool = true

    public static let fields: [ProviderField] = [
        ProviderField(
            key: "apiKey",
            name: "API Key",
            kind: .secure,
            placeholder: "AQ..."
        ),
        ProviderField(
            key: "baseURL",
            name: "Base URL",
            kind: .text,
            placeholder: GeminiLanguageModel.defaultBaseURL.absoluteString,
            isAdvanced: true,
            defaultValue: GeminiLanguageModel.defaultBaseURL.absoluteString
        ),
        ProviderField(
            key: "apiVersion",
            name: "API Version",
            kind: .text,
            placeholder: GeminiLanguageModel.defaultAPIVersion,
            isAdvanced: true,
            defaultValue: GeminiLanguageModel.defaultAPIVersion
        )
    ]

    public init(baseURL: URL = GeminiLanguageModel.defaultBaseURL , apiKey: String, version: String = GeminiLanguageModel.defaultAPIVersion) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.apiVersion = version
    }

    /// Builds an `GeminiProvider` from collected form input.
    ///
    /// - Parameter values: Field input keyed by ``ProviderField/key``.
    /// - Returns: A configured provider.
    /// - Throws: ``ProviderConfigurationError`` when the API key is missing or the base URL is malformed.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public static func make(from values: [String: String]) throws -> GeminiProvider {
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
        
        guard let apiVersion = values["apiVersion"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            throw ProviderConfigurationError.missingField("API Version")
        }

        return GeminiProvider(baseURL: baseURL, apiKey: apiKey, version: apiVersion)
    }
    
    public static func make(from configuration: ConfiguredProvider) throws -> GeminiProvider {
        guard let apiKey = configuration.getConfigurationValue(for: "apiKey") else {
            throw ProviderConfigurationError.missingField("API Key")
        }
        
        guard let raw = configuration.getConfigurationValue(for: "baseURL") else {
            throw ProviderConfigurationError.missingField("Base URL")
        }
        
        guard let baseURL = URL(string: raw) else {
            throw ProviderConfigurationError.invalidValue(field: "Base URL", value: raw)
        }
        
        guard let apiVersion = configuration.getConfigurationValue(for: "apiVersion") else {
            throw ProviderConfigurationError.missingField("API Version")
        }
        
        return GeminiProvider(baseURL: baseURL, apiKey: apiKey, version: apiVersion)
    }
    
    public func getModel(id: String) -> any AnyLanguageModel.LanguageModel {
        return GeminiLanguageModel(baseURL: baseURL, apiKey: apiKey, apiVersion: apiVersion, model: id)
    }
    
    /// Fetches the list of model identifiers available from the Anthropic API.
    ///
    /// - Returns: The `id` of every model returned by the endpoint.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public func availableModels() async throws -> [Model] {
        var request = URLRequest(url: baseURL.appendingPathComponent("\(apiVersion)/models"))
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let modelList = try JSONDecoder().decode(GeminiModelList.self, from: data)
        return modelList.models.filter({ model in
            // Filter to models that support content generation
            return model.supportedGenerationMethods?.contains("generateContent") ?? false
        }).map { item in
            SimpleModel(id: item.name, displayName: item.displayName ?? item.name, provider: GeminiProvider.self)
        }
    }
}

/// The response payload returned by Gemini's `GET /v1/models` endpoint.
///
/// - Authored by: Claude Opus 4.8 (Anthropic)
fileprivate struct GeminiModelList: Decodable {
    struct Model: Decodable {
        let name: String
        let version: String
        let displayName: String?
        let description: String?
        let inputTokenLimit: Int?
        let outputTokenLimit: Int?
        let supportedGenerationMethods: [String]?
        let temperature: Double?
        let topP: Double?
        let topK: Int?
        let maxTemperature: Double?
        let thinking: Bool?
    }

    let models: [Model]
}
