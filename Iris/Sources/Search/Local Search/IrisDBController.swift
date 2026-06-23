//
//  IrisDBController.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

import Foundation
import IrisSearch
import Digester
import SwiftData

enum IrisDBControllerError: Error {
    case unableToObtainSecurityAccess
    case unableToGetContentType
}

@MainActor
final class IrisDBController {
    @MainActor public private(set) var mainContext: IrisContext!
    
    private let irisDB: IrisDB
    private let textEmbedder: EmbeddingProvider
    private let textChunker: TextChunker = BasicTextChunker()
    
    private(set) var runningIndices: Set<UUID> = []
    
    init() {
        do {
            let searchDirectory = Utilities.irisDBDirectory()
            textEmbedder = try NLEmbedder(language: .english)
            irisDB = try IrisDB(databaseLocation: searchDirectory, textEmbedder: textEmbedder, textChunker: textChunker)
        } catch {
            fatalError("Could not create SearchController: \(error)")
        }
        
        mainContext = IrisContext(controllerResult: .success(self))
    }
    
    public func insert(_ file: File) throws {
        let irisDB = irisDB
        let uuid = file.uuid
        let title = file.title
        let description = file.shortDescription
        let scopedURL = try file.securityScopedURL()
        
        runningIndices.insert(file.uuid)
        
        Task(name: "Index \(file.title)", priority: .userInitiated) {
            let accessGranted = scopedURL.startAccessingSecurityScopedResource()
            defer { scopedURL.stopAccessingSecurityScopedResource() }
            
            guard accessGranted else { throw IrisDBControllerError.unableToObtainSecurityAccess }
            
            let fileAttributes = try scopedURL.resourceValues(forKeys: [.contentTypeKey])
            
            guard let contentType = fileAttributes.contentType else { throw IrisDBControllerError.unableToGetContentType }
            
            let digester = try DigesterFactory.digester(for: contentType)
            let embeddableContent = try await digester.digest(file: scopedURL)
            
            try await irisDB.createDocument(uuid: uuid, title: title, description: description, embeddableContent: embeddableContent)
            
            self.runningIndices.remove(file.uuid)
        }
    }
        
    public func delete(_ file: File) {
        let uuid = file.uuid
        let irisDB = irisDB
        
        Task(name: "Delete Search Index for: \(file)", priority: .userInitiated) {
            try await irisDB.deleteDocument(uuid: uuid)
            self.runningIndices.remove(file.uuid)
        }
    }
}

extension IrisDBController: Searchable {
    func search(query: String) async throws {
        
    }
}
