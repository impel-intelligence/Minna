//
//  FileSearchIndexWriter.swift
//  Iris
//
//  Created by Taylor Lineman on 6/20/26.
//

import Foundation
import SwiftData
import IrisSearch
import Digester

@ModelActor
actor FileSearchIndexWriter {
    func generateDescription(for id: PersistentIdentifier, irisDB: IrisDB) async throws {
        guard let file = self[id, as: File.self], !file.isDeleted else { return }

        let scopedURL = try file.securityScopedURL()
        
        guard !file.isDeleted else { return }
        
        let accessGranted = scopedURL.startAccessingSecurityScopedResource()
        defer { scopedURL.stopAccessingSecurityScopedResource() }
        
        guard accessGranted else { throw IrisDBControllerError.unableToObtainSecurityAccess }
        
        let fileAttributes = try scopedURL.resourceValues(forKeys: [.contentTypeKey])
        
        guard let contentType = fileAttributes.contentType else { throw IrisDBControllerError.unableToGetContentType }
        
        let digester = try DigesterFactory.digester(for: contentType)
        let embeddableContent = try await digester.digest(file: scopedURL)
        
        guard !file.isDeleted else { return }
        
        try await irisDB.createDocument(uuid: file.uuid, embeddableContent: embeddableContent)
    }
}
