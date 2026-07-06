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
        @Guide(description: "The number of search results to fetch. N must be greater than 0.")
        var nItems: Int
//        @Guide(description: "How verbose should the output be?")
//        var brevity: Brevity
    }
    
    init(database: IrisDB) {
        self.database = database
    }
    
    func call(arguments: Arguments) async throws -> String {
        print("Call Search Tool \(arguments)")
        do {
            let searchResults = try await self.database.search(query: .init(text: arguments.query), nItems: arguments.nItems)
            
            var toolOutput: [String] = ["The following documents are the result of searching '\(arguments.query)'. Each document is separated by a markdown header. Only partial documents are included, the pieces that are included have been deemed as 'important' based on the search query. Document pieces are separated by a new line. Use the getDocument tool to retrieve the full document context."]
            
            for result in searchResults {
                var importantText = ""
                
                // TODO: Fetch the number of pages. Really need to embed document positions into the data that is retrieved for better LLM tool calling.
                if result.importantPieces.isEmpty {
                    let documentPrompt = """
                # Document: \(result.document.title) uuid: {\(result.document.uuid)}
                \(result.document.description)
                """
                    
                    toolOutput.append(documentPrompt)
                } else {
                    for piece in result.importantPieces {
                        guard let text = piece.text else { continue }
                        importantText.append(text + "\n\n")
                    }
                    
                    let documentPrompt = """
                ## Document: \(result.document.title) uuid: {\(result.document.uuid)}
                
                \(importantText)
                """
                    
                    toolOutput.append(documentPrompt)
                }
            }
            
            return toolOutput.joined(separator: "\n")
        } catch {
            return "Failed to run search: \(error)."
        }
    }
}

