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
    
    private var backgroundWorker: BackgroundWorker? = nil
    
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
    
    public func setWorker(_ worker: BackgroundWorker) {
        self.backgroundWorker = worker
    }
    
    public func insert(_ file: File) throws {
        let irisDB = irisDB
        let uuid = file.uuid
        let title = file.title
        let description = file.shortDescription
        let scopedURL = try file.securityScopedURL()
        
        backgroundWorker?.enqueue(BlockBackgroundTask(name: "Index \(file.title)") {
            let accessGranted = scopedURL.startAccessingSecurityScopedResource()
            defer { scopedURL.stopAccessingSecurityScopedResource() }
            
            guard accessGranted else { throw IrisDBControllerError.unableToObtainSecurityAccess }
            
            let fileAttributes = try scopedURL.resourceValues(forKeys: [.contentTypeKey])
            
            guard let contentType = fileAttributes.contentType else { throw IrisDBControllerError.unableToGetContentType }
            
            let digester = try DigesterFactory.digester(for: contentType)
            let embeddableContent = try await digester.digest(file: scopedURL)
                        
            try await irisDB.createDocument(uuid: uuid, title: title, description: description, embeddableContent: embeddableContent)
        })
    }
        
    public func delete(_ file: File) {
        let uuid = file.uuid
        let irisDB = irisDB
        
        backgroundWorker?.enqueue(BlockBackgroundTask(name: "Delete Search Index for: \(file)") { [irisDB, uuid] in
            try await irisDB.deleteDocument(uuid: uuid)
        })
    }
    
    private func _delete(file: File) async throws {
    }
}

extension IrisDBController: Searchable {
    func search(query: String) async throws {
        
    }
}
