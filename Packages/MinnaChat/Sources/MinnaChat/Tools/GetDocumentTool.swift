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
        @Guide(description: "The end of the document piece range to retrieve.")
        var pieceEndRange: Int
    }
    
    init(database: IrisDB) {
        self.database = database
    }
    
    func call(arguments: Arguments) async throws -> String {
        guard let document = try await database.readDocument(title: arguments.title) else {
            return "No Document Found"
        }
        
        print("Called document tool with \(arguments.title)")

        return document.pieces.compactMap({$0.text}).joined(separator: "\n")
//        if let document {
//            return """
//                Document: \(document.title)
//                
//                """
//        } else {
//            return ""
//        }
    }
}

