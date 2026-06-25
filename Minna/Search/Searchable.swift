//
//  Searchable.swift
//  Minna
//
//  Created by Taylor Lineman on 6/18/26.
//

import Foundation

protocol Searchable {
    func search(query: String) async throws -> [UUID]
}
