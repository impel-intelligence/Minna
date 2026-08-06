//
//  MinnaModelConfig.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/6/26.
//

import Foundation

public struct LLMModelConfig: Codable, Sendable {
    public let identifier: String
    public let displayName: String
    
    public let temperature: Double?
    public let topP: Double?
    public let topK: Double?
    public let minP: Double?
    public let presencePenalty: Double?
    public let repetitionPenalty: Double?
    
    public init(identifier: String, displayName: String, temperature: Double?, topP: Double?, topK: Double?, minP: Double?, presencePenalty: Double?, repetitionPenalty: Double?) {
        self.identifier = identifier
        self.displayName = displayName
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.minP = minP
        self.presencePenalty = presencePenalty
        self.repetitionPenalty = repetitionPenalty
    }

    public static func load(from url: URL) throws -> LLMModelConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(LLMModelConfig.self, from: data)
    }
    
    public func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }

}
