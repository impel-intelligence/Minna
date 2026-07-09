//
//  CitationURLTests.swift
//  Minna
//
//  Created by Taylor Lineman on 7/9/26.
//

@testable import Minna
import SwiftUI
import Testing

struct CitationURLTests {
    @MainActor
    @Test func citationProducesProperURL() throws {
        let citation = Citation(id: UUID(), title: "HelloWorld")
        let url = try #require(citation.urlComponents.url, "A URL should be created from urlComponents.")
        
        #expect(url.absoluteString.starts(with: "minna://"), "URL does not contain the minna scheme.")
        #expect(url.absoluteString.contains("/doc/"), "Doc path does not exist in a citation URL.")
        #expect(url.absoluteString.contains("?title=HelloWorld"), "Citation title query does not exist in URL.")
    }
}
