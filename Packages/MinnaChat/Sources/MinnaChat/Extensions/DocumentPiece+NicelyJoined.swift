//
//  DocumentPiece+NicelyJoined.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/13/26.
//

import IrisCommon
import IrisSearch

extension Array where Element == DocumentPiece {
    func nicelyJoined() -> String {
        var builder: String = ""
        for piece in self {
            guard let text = piece.text else { continue }
            let pieceText = """
                        ## Excerpt "\(piece.content.location.sequenceIndex)" out of \(piece.content.location.documentLength): \(piece.content.location.anchor.description)
                        
                        \(text)
                        """
            
            builder.append(pieceText + "\n")
        }
        
        return builder
    }
}
