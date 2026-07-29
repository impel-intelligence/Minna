//
//  CitationMarkupParser.swift
//  Minna
//
//  Created by Taylor Lineman on 7/5/26.
//  Ideas from: Claude Opus 4.8 (Anthropic)
//

import Foundation
import SwiftUI
import Textual
import OrderedCollections

struct Citation: Hashable, Identifiable {
    let id: UUID
    let title: String
    let pieces: [Int]
    
    var urlComponents: URLComponents {
        return urlComponents(pieces: pieces)
    }
        
    func backup(pieces: [Int]) -> String {
        "minna://doc/\(id)?excerpts=\(pieces.map(String.init).joined(separator: ","))"
    }
    
    func urlComponents(pieces: [Int]) -> URLComponents {
        var components = URLComponents()
        components.scheme = "minna"
        components.host = "doc"
        components.path = "/\(id.uuidString)"
        
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "excerpts", value: pieces.map(String.init).joined(separator: ","))
        ]
        
        return components
    }

}

/// A ``MarkupParser`` that understands `<cite doc_id="…" title="…"/>` markup.
///
/// Each citation is rendered as a small, raised, superscript-style number (`¹`, `²`, …) that is
/// numbered by order of appearance and remains tappable via a `cite://<doc_id>` link. Everything
/// else is delegated to Textual's built-in Markdown parser.
@Observable
class CitationHandler: MarkupParser {
    private let base: AttributedStringMarkdownParser

    var citations: OrderedSet<Citation> = []
    var citationSidebarOpen: Bool = false
    var hasOpenedCitationsOnce: Bool = false

    init() {
        self.base = AttributedStringMarkdownParser(baseURL: nil) // (baseURL: URL(string: "iris://"))
    }

    func attributedString(for input: String) throws -> AttributedString {
        let citedText = input.replaceCitations(existing: self.citations)
        self.citations = citedText.citations
        
        // Only pop the citations open once. If the user closes it manually we don't want to re-open it.
        if !citations.isEmpty && !citationSidebarOpen && !hasOpenedCitationsOnce {
            citationSidebarOpen = true
            hasOpenedCitationsOnce = true
        }
        
        var attributed = try base.attributedString(for: citedText.text)
        
        // Collect the ranges first: mutating attributes below would otherwise interfere with
        // iterating `runs`. Attribute-only edits don't shift text, so the ranges stay valid.
        let citationRanges = attributed.runs.compactMap { run -> Range<AttributedString.Index>? in
            guard let link = run.link, link.scheme == "minna" else { return nil }
            return run.range
        }

        for range in citationRanges {
            attributed[range].font = .footnote.weight(.semibold)
            attributed[range].baselineOffset = 5
            attributed[range].foregroundColor = .accentColor
            attributed[range].underlineStyle = nil
        }

        return attributed
    }
}

private extension String {
    func deletingSuffix(_ suffix: String) -> String {
        // Check if the string actually ends with the specified suffix
        guard self.hasSuffix(suffix) else { return self }
        // Drop the count of characters and convert the Substring back to a String
        return String(self.dropLast(suffix.count))
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        // Check if the string actually ends with the specified prefix
        guard self.hasPrefix(prefix) else { return self }
        // Drop the count of characters and convert the Substring back to a String
        return String(self.dropFirst(prefix.count))
    }
    
    /// Rewrites `<cite doc_id="…" title="…"/>` markup into numbered Markdown links
    /// (`[N](cite://doc_id?title=…)`), numbering citations by order of appearance.
    func replaceCitations(existing existingCitations: OrderedSet<Citation>) -> (text: String, citations: OrderedSet<Citation>) {
        var citations: OrderedSet<Citation> = existingCitations

        let output = self.replacing(/<cite\s+([^>]*?)\s*\/>/) { match in
            let attributes = String(match.output.1)
            guard var docID = attributes.htmlAttribute("doc_id") else {
                return self[match.range]
            }
            // Remove any { } that the AI may have included.
            docID = docID.deletingPrefix("{").deletingSuffix("}")
            
            guard let docUUID = UUID(uuidString: docID) else {
                return self[match.range]
            }
            guard let title = attributes.htmlAttribute("title") else {
                return self[match.range]
            }
            guard let rawPiece = attributes.htmlAttribute("excerpt") else {
                return self[match.range]
            }
            guard let piece = Int(rawPiece) else {
                return self[match.range]
            }
            
            let pieceIndex: Int
            let citation: Citation
            if let existingCitationIndex = citations.firstIndex(where: { $0.id == docUUID }) {
                var existingPieces = citations[existingCitationIndex].pieces
                
                // If the piece already exists in the pieces do not re-add it, but grab its index for the url display
                if let existingIndex = existingPieces.firstIndex(of: piece) {
                    pieceIndex = existingIndex
                } else {
                    // Set the index of the current piece to where it will be inserted.
                    pieceIndex = existingPieces.count
                    existingPieces.append(piece)
                }
                
                citation = Citation(id: docUUID, title: title, pieces: existingPieces)
                citations.remove(at: existingCitationIndex)
                citations.insert(citation, at: existingCitationIndex)
            } else {
                citation = Citation(id: docUUID, title: title, pieces: [piece])
                citations.append(citation)
                pieceIndex = 0
            }
            
            var citationNumber = 1
            
            if let docIndex = citations.firstIndex(of: citation) {
                citationNumber = citations.distance(from: citations.startIndex, to: docIndex) + 1
            }
                        
            // Create a citation that is just the piece this exact citation referenced.
            let url = citation.urlComponents(pieces: [piece]).string ?? citation.backup(pieces: [piece])
            return "[\(citationNumber)s\(pieceIndex + 1)](\(url))"
        }
                
        return (output, citations)
    }
}

private extension String {
    /// Extracts the value of a `name="value"` attribute, allowing any attribute order.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    func htmlAttribute(_ name: String) -> String? {
        guard let regex = try? Regex("\(name)=\"([^\"]*)\"") else { return nil }
        return firstMatch(of: regex)?.output[1].substring.map(String.init)
    }
}
