//
//  DocumentContextTool.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/13/26.
//

import IrisSearch
import AnyLanguageModel
import SwiftData
import Foundation

struct GetExcerptContextTool: Tool {
    let database: IrisDB
    
    let name = "getExcerptContext"
    let description = "Retrieve the pieces of text surrounding a given document piece. Useful for getting the context of an excerpt."
    
    @Generable
    struct Arguments {
        @Guide(description: "The title of the document to retrieve.")
        var title: String
        @Guide(description: "The sequence index of the piece to center the retrieval on")
        var pieceSequenceIndex: Int
        @Guide(description: "How many pieces to retrieve before the center piece.")
        var before: Int
        @Guide(description: "How many pieces to retrieve after the center piece.")
        var after: Int
    }
    
    init(database: IrisDB) {
        self.database = database
    }
    
    func call(arguments: Arguments) async throws -> String {
        let pieces = try await database.readPieceContext(documentTitle: arguments.title, pieceSequenceIndex: arguments.pieceSequenceIndex, before: arguments.before, after: arguments.after)

        print("Called document context tool with \(arguments.title) and range \(arguments.before) - \(arguments.pieceSequenceIndex) - \(arguments.after). Found \(pieces.count) pieces.")
        
        return pieces.nicelyJoined()
    }
}

