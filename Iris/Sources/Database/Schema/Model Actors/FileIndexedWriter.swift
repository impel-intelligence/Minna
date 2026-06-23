//
//  FileIndexWriter.swift
//  Iris
//
//  Created by Taylor Lineman on 6/20/26.
//

import Foundation
import SwiftData
import BlurbKit

@ModelActor
actor FileIndexedWriter {
    func markIndexed(for id: PersistentIdentifier) async throws {
        guard let file = self[id, as: File.self], !file.isDeleted else { return }
        guard !file.isDeleted else { return }
        
        file.needsIndexing = false
        
        try modelContext.save()
    }
}
