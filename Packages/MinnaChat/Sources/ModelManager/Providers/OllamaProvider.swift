//
//  OllamaProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/29/26.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema

public struct OllamaProvider: ModelProvider, Sendable {
    let endpoint: URL
    
    public static let id: String = "ollama"
    public static let editable: Bool = true

    public static let fields: [ProviderField] = [
        ProviderField(
            key: "endpointURL",
            name: "Endpoint",
            kind: .text,
            placeholder: "http://127.0.0.1:11434"
        )
    ]

    public init(endpoint: URL) {
        self.endpoint = endpoint
    }

    /// Builds an `OllamaProvider` from collected form input.
    ///
    /// - Parameter values: Field input keyed by ``ProviderField/key``.
    /// - Returns: A configured provider.
    /// - Throws: ``ProviderConfigurationError`` when the API key is missing or the base URL is malformed.
    public static func make(from values: [String: String]) throws -> OllamaProvider {
        let endpointURL: URL
        if let raw = values["endpointURL"]?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            guard let parsed = URL(string: raw) else {
                throw ProviderConfigurationError.invalidValue(field: "Endpoint", value: raw)
            }
            endpointURL = parsed
        } else {
            endpointURL = AnthropicLanguageModel.defaultBaseURL
        }

        return OllamaProvider(endpoint: endpointURL)
    }
    
    public static func make(from configuration: ConfiguredProvider) throws -> OllamaProvider {
        guard let rawEndpoint = configuration.getConfigurationValue(for: "endpointURL") else {
            throw ProviderConfigurationError.missingField("Endpoint")
        }
                
        guard let endpoint = URL(string: rawEndpoint) else {
            throw ProviderConfigurationError.invalidValue(field: "Endpoint", value: rawEndpoint)
        }
        
        return OllamaProvider(endpoint: endpoint)
    }
    
    public func getModel(id: String) -> any AnyLanguageModel.LanguageModel {
        return OllamaLanguageModel(baseURL: endpoint, model: id)
    }
    
    /// Fetches the list of model identifiers available from the Anthropic API.
    ///
    /// - Returns: The `id` of every model returned by the endpoint.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public func availableModels() async throws -> [Model] {
        var request = URLRequest(url: endpoint.appendingPathComponent("api/tags"))
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let modelList = try JSONDecoder().decode(OllamaModelList.self, from: data)
        return modelList.models.map { item in
            Model(id: item.model, displayName: item.name, provider: OllamaProvider.self)
        }
    }
}

/// The response payload returned by Ollama's `GET /api/tag` endpoint.
fileprivate struct OllamaModelList: Decodable {
    struct Model: Decodable {
        struct Details: Decodable {
            let format: String?
            let family: String?
            let families: [String]?
            let parameterSize: String?
            let quantizationLevel: String?
            
            enum CodingKeys: String, CodingKey {
                case format
                case family
                case families
                case parameterSize = "parameter_size"
                case quantizationLevel = "quantization_level"
            }
        }
        
        let name: String
        let model: String
        let remoteModel: String?
        let modifiedAt: String
        let size: Int
        let digest: String
        let details: Details
        
        enum CodingKeys: String, CodingKey {
            case name
            case model
            case remoteModel = "remote_model"
            case modifiedAt = "modified_at"
            case size
            case digest
            case details
        }
    }

    let models: [Model]
}

