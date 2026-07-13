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
        @Guide(description: "The start of the range of document pieces to retrieve. Some documents have many pieces, use this range to paginate through a document or find a specific range.")
        var pieceStartRange: Int
        @Guide(description: "The non-inclusive end of the document piece range to retrieve. Can NOT be the same as pieceStartRange, and must be greater than pieceStartRange.")
        var pieceEndRange: Int
    }
    
    init(database: IrisDB) {
        self.database = database
    }
    
    func call(arguments: Arguments) async throws -> String {
        // We have a valid range
        if arguments.pieceStartRange >= 0 &&
            arguments.pieceEndRange >= 0 &&
            arguments.pieceStartRange < arguments.pieceEndRange {
            return try await callWithRange(arguments: arguments)
        } else {
            return try await callWithoutRange(arguments: arguments)
        }
    }
    
    private func callWithRange(arguments: Arguments) async throws -> String {
        let range = arguments.pieceStartRange..<arguments.pieceEndRange
        
        guard let document = try await database.readDocument(title: arguments.title, pieceSequenceRange: range) else {
            return "No Document Found"
        }
        
        print("Called document tool with \(arguments.title) and range \(arguments.pieceStartRange)..<\(arguments.pieceEndRange)")
        
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

