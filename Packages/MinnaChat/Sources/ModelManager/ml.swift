//
//  Model.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

import AnyLanguageModel

enum Mod {
    enum ConstructionError: Error {
        case invalidID
    }
    
    // Local
    case mlx(model: String)
    
    // API Based
    case anthropic(model: String)
    case gemini(model: String)
    case ollama(model: String)
    case openAI(model: String)
    case openResponses(model: String)
    
    var languageModel: LanguageModel {
        get throws {
            switch self {
            case .mlx(let model):
                guard let id = Repo.ID(stringLiteral: model) else { throw ConstructionError.invalidID }
                return MLXLanguageModel(modelId: model, directory: HubCache.minnaCacheFolder)
            case .anthropic(let model):
                return AnthropicLanguageModel()
            case .gemini(let model):
                return GeminiLanguageModel()
            case .ollama(let model):
                return OllamaLanguageModel()
            case .openAI(let model):
                return OpenAILanguageModel()
            case .openResponses(let model):
                return OpenResponsesLanguageModel()
            }

        }
    }
}
