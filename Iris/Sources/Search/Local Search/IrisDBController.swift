//
//  IrisDBController.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

import Foundation
import IrisSearch
import Digester

enum IrisDBControllerError: Error {
    case unableToObtainSecurityAccess
    case unableToGetContentType
}

@MainActor
final class IrisDBController {
    private struct WaitingDocument: Identifiable, Hashable, Sendable {
        let id: UUID
        let url: URL
    }
    
    @MainActor public private(set) var mainContext: IrisContext!
    
    private let irisDB: IrisDB
    private let textEmbedder: EmbeddingProvider
    private let textChunker: TextChunker = BasicTextChunker()
    
    private let insertWorkQueue: WorkQueue = WorkQueue()
    
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
        
        guard accessGranted else { throw IrisDBControllerError.unableToObtainSecurityAccess }
        
        let fileAttributes = try document.url.resourceValues(forKeys: [.contentTypeKey])
        
        guard let contentType = fileAttributes.contentType else { throw IrisDBControllerError.unableToGetContentType }
        
        let digester = try DigesterFactory.digester(for: contentType)
        let embeddableContent = try await digester.digest(file: document.url)
        
        try await irisDB.createDocument(uuid: document.id, embeddableContent: embeddableContent)
    }
}

extension IrisDBController: Searchable {
    func search(query: String) async throws {
        
    }
}
