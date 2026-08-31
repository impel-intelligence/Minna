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
import DatabaseSchema
import Logging
import IrisCommon
import AppleIntelligenceEmbedder
import CoreMLEmbedder
import ModelCDN

enum IrisDBControllerError: Error {
    case unableToObtainSecurityAccess
    case unableToGetContentType
}

enum IrisDBControllerInitializationError: Error {
    case noAppleIntelligence
    case noCoreMLModel
}

@MainActor @Observable
final class IrisDBController {
    // TODO: This should be adjustable.
    static let searchEmbedderID: String = "bge_small_en_v1.5"
    
    @ObservationIgnored let irisDB: IrisDB
    @ObservationIgnored private var textEmbedder: EmbeddingProvider
    
    var indexingProgress: IndexingProgress = IndexingProgress()
    let fileIndexedWriter: FileIndexedWriter

    /// An indexing queue to bound the total number of running import jobs. Stops task fanning on massive imports.
    @ObservationIgnored private let indexingQueue: RateLimitedQueue = RateLimitedQueue(maxConcurrency: 3)

    init(modelContainer: ModelContainer) throws {
        fileIndexedWriter = FileIndexedWriter(modelContainer: modelContainer)
        
        let embedder: EmbeddingProvider = try IrisDBController.getEmbedder()
        
        self.textEmbedder = embedder
        
        let searchDirectory = Utilities.irisDBDirectory()
        irisDB = try IrisDB(databaseLocation: searchDirectory, textEmbedder: textEmbedder)
        
        // TODO: Watch for downloads so we can re-embed the database
    }
    
    func runMaintenance() async throws {
        if await irisDB.requiresFaissMigration {
            do {
                var progress = Progress()
                try await irisDB.migrateFromFaissIndex(progress: progress)
            } catch {
                Log.logger.error("Failed to migrate from faiss index", error: error)
            }
        }
        
        if await irisDB.requiresRepair {
            do {
                try await irisDB.repairDatabase()
            } catch {
                Log.logger.error("Failed to repair iris database", error: error)
            }
        }
    }
    
    private static func getEmbedder() throws -> EmbeddingProvider {
        do {
            let bgeDirectory = ManifestSharedSettings.modelStorageURL.appendingPathComponent(searchEmbedderID, conformingTo: .directory)
            return try CoreMLEmbedder(modelDirectory: bgeDirectory)
        } catch {
            Log.logger.debug("Failed to load CoreMLEmbedder", error: error)
            
            // Try and create the embedder, if we can't it is because Apple Intelligence is not available
            do {
                return try NLContextualEmbedder(language: .english)
            } catch {
                Log.logger.debug("Failed to load NLContextualEmbedder", error: error)
                
                // Load the backup embedder, if we can't load it, Apple Intelligence is not enabled and we wont be able to do on-device intelligence.
                do {
                    return try NLEmbedder(language: .english)
                } catch {
                    Log.logger.debug("Failed to load NLEmbedder", error: error)
                    throw IrisDBControllerInitializationError.noAppleIntelligence
                }
            }
        }
    }
    
    public func reEmbedDatabase() async throws {
        let documents = try await irisDB.readAllDocuments()
        
        let irisDB = irisDB
        
        for document in documents {
            indexingProgress.add(id: document.uuid)

            indexingQueue.enqueue { [ weak self] in
                do {
                    try await irisDB.updateDocument(uuid: document.uuid, title: document.title, description: document.description, embeddableContent: document.pieces.map(\.content))
                    await self?.completeIndexing(uuid: document.uuid)
                } catch {
                    Log.logger.error("Failed to re-embed entire database", error: error)
                }
            }
        }
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
                
                let embeddableContent = try await digester.digest(file: scopedURL, contextSize: irisDB.contextSize)
               
                try await irisDB.createDocument(uuid: uuid, title: title, description: description, embeddableContent: embeddableContent)

                try await fileIndexedWriter.markIndexed(for: persistentID)

                await self?.completeIndexing(uuid: uuid)
            } catch {
                Log.logger.error("Failed to index file", error: error, metadata: ["uuid": "\(uuid.uuidString)", "name": "\(title)"])
                SentrySDK.capture(error: error)
                // Clear progress even on failure so the indexing indicator never hangs.
                await self?.completeIndexing(uuid: uuid)
            }
        }
    }

    private func completeIndexing(uuid: UUID) {
        indexingProgress.complete(id: uuid)
    }
        
    public func delete(_ file: File) throws {
//        guard let irisDB = irisDB else { throw IrisDBControllerError.notConnectedToDatabase }
        let irisDB = irisDB
        let uuid = file.uuid
        
        Task(name: "Delete Search Index for: \(file)", priority: .userInitiated) {
            try await irisDB.deleteDocument(uuid: uuid)
            indexingProgress.cancel(id: uuid)
        }
    }
    
    public func search(query: String) async throws -> [UUID] {
        #if DEBUG
        let query = IrisQuery(text: query, debug: true)
        #else
        let query = IrisQuery(text: query)
        #endif
        let documents = try await irisDB.search(query: query, ranking: .relativeScoreFusion)

        return documents.map { $0.document.uuid }
    }
}
