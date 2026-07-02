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
    let description = "Retrieve documents from the user's knowledge database."
    
    @Generable
    struct Arguments {
        @Guide(description: "The natural language or SQL FTS5 query to search. One query can contain both natural language and FTST queries, however the accuracy of the natural language portion of search results will be reduced.")
        var query: String
        @Guide(description: "The number of search results to fetch.")
        var nItems: Int
//        @Guide(description: "How verbose should the output be?")
//        var brevity: Brevity
    }
    
    init(database: IrisDB) {
        self.database = database
    }
    
    func call(arguments: Arguments) async throws -> String {
        print("Call Search Tool")
        let searchResults = try await self.database.search(query: .init(text: arguments.query), nItems: arguments.nItems)
        
        var toolOutput: String = ""
        
        for result in searchResults {
            var importantText = ""
            
            if result.importantPieces.isEmpty {
                let documentPrompt = """
                ## Document: \(result.document.title)
                \(result.document.description)
                """

                toolOutput.append(documentPrompt)
            } else {
                for piece in result.importantPieces {
                    guard let text = piece.text else { continue }
                    importantText.append(text + "\n\n")
                }
                
                let documentPrompt = """
                ## Document: \(result.document.title)
                The following are pieces of this document that best matched the search. Use the getDocument tool to retrieve the full document context. Pieces are separated by two new lines. 
                
                \(importantText)
                """
                
                toolOutput.append(documentPrompt)
            }
        }
        
        print("Called search tool with '\(arguments.query)', \(arguments.nItems)\n\(toolOutput)")
        
        return toolOutput
    }
}

