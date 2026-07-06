//
//  CitationMarkupParser.swift
//  Minna
//
//  Created by Claude Opus 4.8 (Anthropic) on 2026-07-05
//

import Foundation
import SwiftUI
import Textual
import OrderedCollections

struct Citation: Hashable, Identifiable {
    let id: UUID
    let title: String
    
    var urlComponents: URLComponents {
        var components = URLComponents()
        components.scheme = "iris"
        components.host = id.uuidString
        components.queryItems = [URLQueryItem(name: "title", value: title)]
        
        return components
    }
}

/// A ``MarkupParser`` that understands `<cite doc_id="…" title="…"/>` markup.
///
/// Each citation is rendered as a small, raised, footnote-style number (`¹`, `²`, …) that is
/// numbered by order of appearance and remains tappable via a `cite://<doc_id>` link. Everything
/// else is delegated to Textual's built-in Markdown parser.
///
/// - Authored by: Claude Opus 4.8 (Anthropic)
@Observable
class CitationHandler: MarkupParser {
    private let base: AttributedStringMarkdownParser

    var citations: OrderedSet<Citation> = []

    init() {
        self.base = AttributedStringMarkdownParser(baseURL: nil) // (baseURL: URL(string: "iris://"))
    }

    func attributedString(for input: String) throws -> AttributedString {
        let citedText = input.replaceCitations(existing: self.citations)
        self.citations.formUnion(citedText.citations)
        
        var attributed = try base.attributedString(for: citedText.text)
        
        // Collect the ranges first: mutating attributes below would otherwise interfere with
        // iterating `runs`. Attribute-only edits don't shift text, so the ranges stay valid.
        let citationRanges = attributed.runs.compactMap { run -> Range<AttributedString.Index>? in
            guard let link = run.link, link.scheme == "iris" else { return nil }
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
    /// Rewrites `<cite doc_id="…" title="…"/>` markup into numbered Markdown links
    /// (`[N](cite://doc_id?title=…)`), numbering citations by order of appearance.
    func replaceCitations(existing existingCitations: OrderedSet<Citation>) -> (text: String, citations: OrderedSet<Citation>) {
        var citations: OrderedSet<Citation> = existingCitations

        let output = self.replacing(/<cite\s+([^>]*?)\s*\/>/) { match in
            let attributes = String(match.output.1)
            guard let docID = attributes.htmlAttribute("doc_id") else {
                return self[match.range]
            }
            guard let docUUID = UUID(uuidString: docID) else {
                return self[match.range]
            }
            guard let title = attributes.htmlAttribute("title") else {
                return self[match.range]
            }
            
            let citation = Citation(id: docUUID, title: title)
            
            if !citations.contains(citation) {
                citations.append(citation)
            }
            
            var citationNumber = 1
            
            if let docIndex = citations.firstIndex(of: citation) {
                citationNumber = citations.distance(from: citations.startIndex, to: docIndex) + 1
            }
                        
            return "[\(citationNumber)](\(citation.urlComponents.string ?? "iris://\(docID)"))"
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
