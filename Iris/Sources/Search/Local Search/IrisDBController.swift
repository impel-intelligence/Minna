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
    
    public func insert(_ file: File) {
        let indexWriter: FileSearchIndexWriter = FileSearchIndexWriter(modelContainer: <#T##ModelContainer#>)

        backgroundWorker?.enqueue(BlockBackgroundTask { @MainActor [weak self] in
            try await self?._insert(file: file)
        })
    }
        
    public func delete(_ file: File) {
        backgroundWorker?.enqueue(BlockBackgroundTask { @MainActor [weak self] in
            try await self?._delete(file: file)
        })
    }
    
    private func _delete(file: File) async throws {
        try await self.irisDB.deleteDocument(uuid: file.uuid)
    }
}

extension IrisDBController: Searchable {
    func search(query: String) async throws {
        
    }
}
