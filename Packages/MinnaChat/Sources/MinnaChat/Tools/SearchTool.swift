//
//  SearchTool.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/29/26.
//

import IrisSearch
import AnyLanguageModel
import SwiftData
import Foundation

struct SearchTool: Tool {
    let database: IrisDB
    
    let name = "searchDocuments"
    let description = "Retrieve documents from the user's knowledge corpus."
    
    @Generable
    struct Arguments {
        @Guide(description: "The natural language or SQL FTS5 query to search.")
        var query: String
        @Guide(description: "The number of search results to fetch.")
        var nItems: Int
    }
    
    init(database: IrisDB) {
        self.database = database
    }
    
    func call(arguments: Arguments) async throws -> String {
        let documents = try await self.database.search(query: .init(text: arguments.query), nItems: arguments.nItems)
        
        var toolOutput: String = ""
        
//        for document in documents {
//            let documentString = document.pieces.map({$0.content}).compactMap { content in
//                switch content {
//                case .text(let content):
//                    return content
//                case .image(_, let caption):
//                    return caption
//                }
//            }
//            
//            toolOutput += "=== Document: \(document.title) ===\n\(documentString)\n === END Document ==="
//        }
//        
        return toolOutput
    }
}

