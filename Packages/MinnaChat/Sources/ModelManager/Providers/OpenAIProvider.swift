//
//  OpenAIProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/4/26.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema

public struct OpenAIProvider: ModelProvider, Sendable {
    let baseURL: URL
    let apiKey: String

    public static let id: String = "openai"
    public static let editable: Bool = true

    public static let fields: [ProviderField] = [
        ProviderField(
            key: "apiKey",
            name: "API Key",
            kind: .secure,
            placeholder: "sk-..."
        ),
        ProviderField(
            key: "baseURL",
            name: "Base URL",
            kind: .text,
            placeholder: OpenAILanguageModel.defaultBaseURL.absoluteString,
            isAdvanced: true,
            defaultValue: OpenAILanguageModel.defaultBaseURL.absoluteString
        )
    ]

    public init(baseURL: URL = OpenAILanguageModel.defaultBaseURL , apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    /// Builds an `OpenAIProvider` from collected form input.
    ///
    /// - Parameter values: Field input keyed by ``ProviderField/key``.
    /// - Returns: A configured provider.
    /// - Throws: ``ProviderConfigurationError`` when the API key is missing or the base URL is malformed.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public static func make(from values: [String: String]) throws -> OpenAIProvider {
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
            baseURL = OpenAILanguageModel.defaultBaseURL
        }

        return OpenAIProvider(baseURL: baseURL, apiKey: apiKey)
    }
    
    public static func make(from configuration: ConfiguredProvider) throws -> OpenAIProvider {
        guard let apiKey = configuration.getConfigurationValue(for: "apiKey") else {
            throw ProviderConfigurationError.missingField("API Key")
        }
        
        guard let raw = configuration.getConfigurationValue(for: "baseURL") else {
            throw ProviderConfigurationError.missingField("Base URL")
        }
        
        guard let parsed = URL(string: raw) else {
            throw ProviderConfigurationError.invalidValue(field: "Base URL", value: raw)
        }
        
        return OpenAIProvider(baseURL: parsed, apiKey: apiKey)
    }
    
    public func getModel(id: String) -> any AnyLanguageModel.LanguageModel {
        return OpenAILanguageModel(baseURL: baseURL, apiKey: apiKey, model: id, apiVariant: .responses)
    }
    
    /// Fetches the list of model identifiers available from the OpenAI API.
    ///
    /// - Returns: The `id` of every model returned by the endpoint.
    public func availableModels() async throws -> [any Model] {
        var request = URLRequest(url: baseURL.appendingPathComponent("models"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let modelList = try JSONDecoder().decode(OpenAIModelList.self, from: data)
        return modelList.data.sorted(by: { lhs, rhs in
            lhs.created > rhs.created
        }).map { item in
            SimpleModel(id: item.id, displayName: item.id, provider: OpenAIProvider.self)
        }
    }
    
    public func generationOptions(model: any Model) -> AnyLanguageModel.GenerationOptions {
        return GenerationOptions(maximumResponseTokens: 4096)
    }
}

/// The response payload returned by OpenAI's `GET /models` endpoint.
fileprivate struct OpenAIModelList: Decodable {
    struct Model: Decodable {
        let id: String
        let object: String
        let created: Int
        let ownedBy: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case object
            case created
            case ownedBy = "owned_by"
        }
    }

    let data: [Model]
}

