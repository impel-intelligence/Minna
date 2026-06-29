//
//  MinnaDBController.swift
//  Minna
//
//  Created by Taylor Lineman on 6/18/26.
//

import Foundation
import IrisSearch
import Digester
import SwiftData
import SentrySwift
import UniformTypeIdentifiers

enum IrisDBControllerError: Error {
    case unableToObtainSecurityAccess
    case unableToGetContentType
}

struct IndexingProgress {
    var completed: Set<UUID> = []
    var inProgress: Set<UUID> = []
    
    var total: Int { completed.count + inProgress.count }
    
    var fractionCompleted: Double { total == 0 ? 1 : Double(completed.count) / Double(total) }
    var isIndexing: Bool { !inProgress.isEmpty }
    
    mutating func add(id: UUID) {
        inProgress.insert(id)
    }
    
    mutating func complete(id: UUID) {
        // If this id does not exist in the inProgress array, it has been canceled and we don't want to set it to be true.
        guard inProgress.contains(id) else { return }
        
        inProgress.remove(id)
        completed.insert(id)
        
        // Reset the indexing
        if inProgress.isEmpty {
            completed.removeAll()
            inProgress.removeAll()
        }
    }
    
    mutating func cancel(id: UUID) {
        inProgress.remove(id)
        completed.remove(id)
        
        // Reset the indexing
        if inProgress.isEmpty {
            completed.removeAll()
            inProgress.removeAll()
        }
    }
}

@MainActor @Observable
final class IrisDBController {
    @MainActor public private(set) var mainContext: IrisContext!
    
    @ObservationIgnored let irisDB: IrisDB
    @ObservationIgnored private let textEmbedder: EmbeddingProvider
    @ObservationIgnored private let textChunker: TextChunker = BasicTextChunker()
    
    var indexingProgress: IndexingProgress = IndexingProgress()
    let fileIndexedWriter: FileIndexedWriter

    /// An indexing queue to bound the total number of running import jobs. Stops task fanning on massive imports.
    @ObservationIgnored private let indexingQueue: RateLimitedQueue = RateLimitedQueue(maxConcurrency: 3)

    init(modelContainer: ModelContainer) {
        do {
            let searchDirectory = Utilities.irisDBDirectory()
            textEmbedder = try NLContextualEmbedder(language: .english)
            irisDB = try IrisDB(databaseLocation: searchDirectory, textEmbedder: textEmbedder, textChunker: textChunker)
        } catch {
            SentrySDK.capture(error: error)
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
        
        let fileIndexedWriter = fileIndexedWriter

        indexingProgress.add(id: uuid)

        // Route through the queue so a bulk import can't spawn one unbounded
        // task per file, each holding a full file's contents + embeddings in memory.
        indexingQueue.enqueue { [weak self] in
            do {
                let accessGranted = scopedURL.startAccessingSecurityScopedResource()
                defer { scopedURL.stopAccessingSecurityScopedResource() }

                guard accessGranted else { throw IrisDBControllerError.unableToObtainSecurityAccess }

                let fileAttributes = try scopedURL.resourceValues(forKeys: [.contentTypeKey])

                guard let contentType = fileAttributes.contentType else { throw IrisDBControllerError.unableToGetContentType }

                let digester = try DigesterFactory.digester(for: contentType)
                let embeddableContent = try await digester.digest(file: scopedURL)

                try await irisDB.createDocument(uuid: uuid, title: title, description: description, embeddableContent: embeddableContent)

                try await fileIndexedWriter.markIndexed(for: persistentID)

                await self?.completeIndexing(uuid: uuid)
            } catch {
                SentrySDK.capture(error: error)
                // Clear progress even on failure so the indexing indicator never hangs.
                await self?.completeIndexing(uuid: uuid)
            }
        }
    }

    private func completeIndexing(uuid: UUID) {
        indexingProgress.complete(id: uuid)
    }
        
    public func delete(_ file: File) {
        let uuid = file.uuid
        let irisDB = irisDB
        
        Task(name: "Delete Search Index for: \(file)", priority: .userInitiated) {
            try await irisDB.deleteDocument(uuid: uuid)
            indexingProgress.cancel(id: uuid)
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
