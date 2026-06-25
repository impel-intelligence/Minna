//
//  FuzzyMatch.swift
//  Impel
//

import Foundation

extension String {
    /// Fuzzy matches the query against this string and returns a score
    /// that indicates how closely the query matches the string.
    ///
    /// - Parameter query: The string to check against
    /// - Returns: A score that indicates how closely the query matches this string
    func fuzzyMatch(query: String) -> Int {
        do {
            guard !query.isEmpty else { return 1 }
            
            let lowercasedString = query.lowercased()
            let lowercaseSelf = self.lowercased()
            
            let matchBonus = 100
            var score: Int = 0
            
            let regex = try Regex(lowercasedString)
            let matches = lowercaseSelf.matches(of: regex)
            score += (matchBonus * matches.count)
            
            return score
        } catch {
            return 0
        }
    }
    
    func doesAnyContentOverlap(query: String) -> Bool {
        
        // Helper function to extract meaningful keywords
        func extractKeywords(from text: String) -> Set<String> {
            let stopwords: Set<String> = ["is", "are", "the", "a", "an", "and", "or", "but", "on", "in", "with"]
            let words = text.lowercased()
                .components(separatedBy: .punctuationCharacters
                    .union(.whitespacesAndNewlines))
            let filteredWords = Set(words.filter { word in
                !word.isEmpty && !stopwords.contains(word) && word.count > 2
            })
            return filteredWords
        }
        
        // Extract keywords from query
        let queryKeywords = extractKeywords(from: query)
        
        // Check content for any keyword overlap with the query
        let contentKeywords = extractKeywords(from: self)
        if !contentKeywords.intersection(queryKeywords).isEmpty {
            return true  // Return true as soon as a match is found
        }
        return false  // Return false if no matches are found
    }
}
