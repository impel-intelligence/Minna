//
//  Searchable.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

protocol Searchable {
    func search(query: String) async throws
}
