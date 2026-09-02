//
//  SearchInDocumentTool.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/17/26.
//

import IrisSearch
import AnyLanguageModel
import SwiftData
import Foundation

struct SearchInDocumentTool: Tool {
    let database: IrisDB
    
    let name = "searchInDocument"
    let description = "Search within a document for excertps relevant to a query."
    
    @Generable
    struct Arguments {
        @Guide(description: "The title of the document to search in.")
        var title: String
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
        do {
            guard let document = try await database.readDocument(title: arguments.title) else {
                return "No Document Found with title \(arguments.title)"
            }

            let searchResult = try await self.database.search(within: document.uuid, query: .init(text: arguments.query), nItems: arguments.nItems)
            
            return """
            The following excerpts are the result of searching '\(arguments.query)' in the document \(arguments.title). Each excerpt is separated by a markdown header.
            \(searchResult.importantPieces.nicelyJoined())
            """
        } catch {
            return "Failed to run search: \(error)."
        }
    }
}

