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

struct IndexingProgress {
    var completed: Int
    var total: Int
    var fractionCompleted: Double { total == 0 ? 1 : Double(completed) / Double(total) }
    var isIndexing: Bool { completed < total }
    var isCompleted: Bool { completed == total }
    
    mutating func reset() {
        completed = 0
        total = 0
    }
}

@MainActor @Observable
final class IrisDBController {
    @MainActor public private(set) var mainContext: IrisContext!
    
    @ObservationIgnored private let irisDB: IrisDB
    @ObservationIgnored private let textEmbedder: EmbeddingProvider
    @ObservationIgnored private let textChunker: TextChunker = BasicTextChunker()
    
    var indexingProgress: IndexingProgress = IndexingProgress(completed: 0, total: 0)
    let fileIndexedWriter: FileIndexedWriter
    
    init(modelContainer: ModelContainer) {
        do {
            let searchDirectory = Utilities.irisDBDirectory()
            textEmbedder = try NLEmbedder(language: .english)
            irisDB = try IrisDB(databaseLocation: searchDirectory, textEmbedder: textEmbedder, textChunker: textChunker)
        } catch {
            fatalError("Could not create SearchController: \(error)")
        }
        
        fileIndexedWriter = FileIndexedWriter(modelContainer: modelContainer)
        mainContext = IrisContext(controllerResult: .success(self))
    }
        
    public func insert(_ file: File) throws {
        let irisDB = irisDB
        let persistentID = file.persistentModelID
        let uuid = file.uuid
        let title = file.title
        let description = file.shortDescription
        let scopedURL = try file.securityScopedURL()
        
        indexingProgress.total += 1
        
        Task(name: "Index \(file.title)", priority: .userInitiated) {
            let accessGranted = scopedURL.startAccessingSecurityScopedResource()
            defer { scopedURL.stopAccessingSecurityScopedResource() }
            
            guard accessGranted else { throw IrisDBControllerError.unableToObtainSecurityAccess }
            
            let fileAttributes = try scopedURL.resourceValues(forKeys: [.contentTypeKey])
            
            guard let contentType = fileAttributes.contentType else { throw IrisDBControllerError.unableToGetContentType }
            
            let digester = try DigesterFactory.digester(for: contentType)
            let embeddableContent = try await digester.digest(file: scopedURL)
            
            try await irisDB.createDocument(uuid: uuid, title: title, description: description, embeddableContent: embeddableContent)
                        
            try await fileIndexedWriter.markIndexed(for: persistentID)
            
            indexingProgress.completed += 1
                        
            // Reset the indexing
            if indexingProgress.isCompleted {
                indexingProgress.reset()
            }
        }
    }
        
    public func delete(_ file: File) {
        let uuid = file.uuid
        let irisDB = irisDB
        
        Task(name: "Delete Search Index for: \(file)", priority: .userInitiated) {
            try await irisDB.deleteDocument(uuid: uuid)
        }
    }
    
    private func markFileIndexed(file: File) {
        
    }
}

extension IrisDBController: Searchable {
    public func search(query: String) async throws -> [UUID] {
        let query = IrisQuery(text: query)
        let documents = try await irisDB.search(query: query, ranking: .relativeScoreFusion)

        return documents.map { $0.uuid }
    }
}
