//
//  SearchController.swift
//  Minna
//
//  Created by Taylor Lineman on 6/17/26.
//

import Foundation
import IrisSearch
import Digester

@Observable
class SearchController {
    var engines: [Searchable] = []

    func search(query: String) async throws {
        for engine in engines {
            try await engine.search(query: query)
        }
    }
}
