//
//  CloudProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

public enum CloudProvider: Int, CustomStringConvertible {    
    case anthropic
    case gemini
    case llama
    case openAI
    case openResponses
    
    public var description: String {
        switch self {
        case .anthropic:
            return "Anthropic (Claude)"
        case .gemini:
            return "Gemini (Google)"
        case .llama:
            return "Llama"
        case .openAI:
            return "OpenAI"
        case .openResponses:
            return "Open Responses Compatible Provider"
        }
    }
}
