//
//  FileDescriptionWriter.swift
//  Iris
//
//  Created by Taylor Lineman on 6/20/26.
//

import Foundation
import SwiftData
import BlurbKit

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
        
        guard !file.isDeleted else { return }
        file.shortDescription = blurb.description

        try modelContext.save()
    }
}
