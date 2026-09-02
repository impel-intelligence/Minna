//
//  GetDocumentTool.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//

import IrisSearch
import AnyLanguageModel
import SwiftData
import Foundation

struct GetDocumentTool: Tool {
    let database: IrisDB

    let name = "getDocument"
    let description = "Retrieve a singular document from the user's knowledge database by title."
    
    @Generable
    struct Arguments {
        @Guide(description: "The title of the document to retrieve.")
        var title: String
        @Guide(description: "The start of the range of document excerpt to retrieve. Some documents have many excerpts, use this range to paginate through a document or find a specific range.")
        var excerptStartRange: Int
        @Guide(description: "The non-inclusive end of the document excerpt range to retrieve. Can NOT be the same as excerptStartRange, and must be greater than excerptStartRange.")
        var excerptEndRange: Int
    }
    
    init(database: IrisDB) {
        self.database = database
    }
    
    func call(arguments: Arguments) async throws -> String {
        // We have a valid range
        if arguments.excerptStartRange >= 0 &&
            arguments.excerptEndRange >= 0 &&
            arguments.excerptStartRange < arguments.excerptEndRange {
            return try await callWithRange(arguments: arguments)
        } else {
            return try await callWithoutRange(arguments: arguments)
        }
    }
    
    private func callWithRange(arguments: Arguments) async throws -> String {
        let range = arguments.excerptStartRange..<arguments.excerptEndRange
        
        guard let document = try await database.readDocument(title: arguments.title, pieceSequenceRange: range) else {
            return "No Document Found"
        }
        
        print("Called document tool with \(arguments.title) and range \(arguments.excerptStartRange)..<\(arguments.excerptEndRange)")
        
        return document.pieces.nicelyJoined()

    }
    
    private func callWithoutRange(arguments: Arguments) async throws -> String {
        guard let document = try await database.readDocument(title: arguments.title) else {
            return "No Document Found"
        }
        
        print("Called document tool with \(arguments.title)")
        
        return document.pieces.nicelyJoined()
    }
}

