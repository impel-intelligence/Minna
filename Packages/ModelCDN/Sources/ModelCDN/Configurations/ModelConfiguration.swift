//
//  ModelConfiguration.swift
//  ModelCDN
//
//  Created by Taylor Lineman on 8/6/26.
//

import Foundation

struct EmbeddingModelConfig: Codable, Sendable {
    let tokenizerClass: String
    let dimensions: Int
    
    let maximumInputCharactersPerWord: Int
    let cleanText: Bool
    let handleChineseCharacters: Bool
    let stripAccents: Bool?
    let lowercase: Bool
    
    let searchPrefix: String?
    
    static public func load(from url: URL) throws -> EmbeddingModelConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(EmbeddingModelConfig.self, from: data)
    }
    
    
}
