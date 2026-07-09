//
//  FileDescriptionWriter.swift
//  Minna
//
//  Created by Taylor Lineman on 6/20/26.
//

import Foundation
import SwiftData
import BlurbKit
import UniformTypeIdentifiers
import DatabaseSchema

@ModelActor
actor FileDescriptionWriter {
    func generateDescription(for id: PersistentIdentifier) async throws {
        guard let file = self[id, as: File.self], !file.isDeleted else { return }
        guard !file.isDeleted else { return }
        
        let url = try file.securityScopedURL()

        guard let contentType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            print("Failed to get content type for file \(file)")
            return
        }
        
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard hasAccess else {
            print("Unable to obtain security scope")
            return
        }
        
        let blurbProvider = try BlurbFactory.provider(for: contentType)
        
        // Retrieve a file blurb using Apple's Intelligence models.
        let blurb = try await blurbProvider.blurb(for: url)
        
        // Refetch the file and make sure it has not been deleted. This fixes data races after the long wait.
        var descriptor = FetchDescriptor<File>(predicate: #Predicate { $0.persistentModelID == id })
        descriptor.fetchLimit = 1
        guard let liveFile = try modelContext.fetch(descriptor).first else { return }

        liveFile.shortDescription = blurb.description
        liveFile.descriptionGenerated = true

        try modelContext.save()
    }
}
