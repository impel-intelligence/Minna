//
//  FileIndexWriter.swift
//  Minna
//
//  Created by Taylor Lineman on 6/20/26.
//

import Foundation
import SwiftData
import BlurbKit
import DatabaseSchema

@ModelActor
actor FileIndexedWriter {
    func markIndexed(for id: PersistentIdentifier) async throws {
        // We need to re-fetch the file, we can't trust the FileIndexedWriter to have an up to date context for `file.isDeleted` to return a proper value. To get around this, we re-fetch from the context and only continue if the fetch completes.
        var descriptor = FetchDescriptor<File>(predicate: #Predicate { $0.persistentModelID == id })
        descriptor.fetchLimit = 1
        guard let file = try modelContext.fetch(descriptor).first else { return }

        file.searchIndexed = true

        try modelContext.save()
    }
}
