//
//  SearchController.swift
//  Iris
//
//  Created by Taylor Lineman on 6/17/26.
//

import Foundation
import IrisSearch
import Digester

/// A thread-safe queue that processes work items sequentially in the background.
actor WorkQueue {
    typealias WorkItem = () async throws -> Void
    
    private let continuation: AsyncStream<WorkItem>.Continuation
    
    init() {
        let (stream, continuation) = AsyncStream<WorkItem>.makeStream()
        self.continuation = continuation
        
        Task {
            for await workItem in stream {
                do {
                    try await workItem()
                } catch {
                    print("Failed to process work item \(error)")
                }
            }
        }
    }
    
    func enqueue(_ item: @escaping WorkItem) {
        continuation.yield(item)
    }
    
    deinit {
        continuation.finish()
    }
}

enum SearchControllerError: Error {
    case unableToObtainSecurityAccess
    case unableToGetContentType
}

final class SearchController {
    struct WaitingDocument: Identifiable, Hashable, Sendable {
        let id: UUID
        let url: URL
    }
    
    static let shared = SearchController()

    let irisDB: IrisDB
    let textEmbedder: EmbeddingProvider
    let textChunker: TextChunker = BasicTextChunker()
    
    var insertWorkQueue: WorkQueue = WorkQueue()
    
    private init() {
        do {
            let searchDirectory = Utilities.irisDBDirectory()
            textEmbedder = try NLEmbedder(language: .english)
            irisDB = try IrisDB(databaseLocation: searchDirectory, textEmbedder: textEmbedder, textChunker: textChunker)
        } catch {
            fatalError("Could not create SearchController: \(error)")
        }
    }
    
    func insert(_ file: File) {
        var isStale: Bool = false
        var fileURL: URL = file.url
        
        if let bookmark = file.bookmark, let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
            fileURL = url
        }
        
        let document = WaitingDocument(id: file.uuid, url: fileURL)
        
        Task {
            await insertWorkQueue.enqueue { [weak self] in
                try await self?._insert(document: document)
            }
        }
    }
    
    private func _insert(document: WaitingDocument) async throws {
        let accessGranted = document.url.startAccessingSecurityScopedResource()
        defer { document.url.stopAccessingSecurityScopedResource() }
        
        guard accessGranted else { throw SearchControllerError.unableToObtainSecurityAccess }
        
        let fileAttributes = try document.url.resourceValues(forKeys: [.contentTypeKey])
        
        guard let contentType = fileAttributes.contentType else { throw SearchControllerError.unableToGetContentType }
        
        let digester = try DigesterFactory.digester(for: contentType)
        let embeddableContent = try await digester.digest(file: document.url)
        
        try await irisDB.createDocument(uuid: document.id, embeddableContent: embeddableContent)
    }
}
