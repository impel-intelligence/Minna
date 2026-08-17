//
//  Database.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftData
import Foundation
import BlurbKit
import SFSafeSymbols
import SentrySwift
import DatabaseSchema
import FoundationModels

@MainActor
class FrontendDatabase: Database {
    static let shared: FrontendDatabase = FrontendDatabase()

    // Yes there is a spelling mistake in this key, it is too late to change it.
    private static let unfiledFolderKey: String = "unfilled_folder_key"
        
    // Swift Data Variables
    var modelContainer: ModelContainer
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    var unfiledFolderUUID: UUID
    var initializationError: (any Error)?
    
    private var fileDescriptionWriter: FileDescriptionWriter

    private let indexingQueue: RateLimitedQueue = RateLimitedQueue()

    init() {
        if let uuidString = UserDefaults.standard.object(forKey: FrontendDatabase.unfiledFolderKey) as? String, let uuid = UUID(uuidString: uuidString) {
            unfiledFolderUUID = uuid
        } else {
            // TODO: Try and find an existing unfiled folder UUID in case the user defaults got wiped.
            unfiledFolderUUID = UUID()
            UserDefaults.standard.set(unfiledFolderUUID.uuidString, forKey: FrontendDatabase.unfiledFolderKey)
        }

        let modelConfiguration = ModelConfiguration(schema: Schema.minnaSchema)
        
        // Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-13
        do {
            modelContainer = try ModelContainer(
                for: Schema.minnaSchema,
                migrationPlan: DatabaseMigrationPlan.self,
                configurations: modelConfiguration
            )
            fileDescriptionWriter = FileDescriptionWriter(modelContainer: modelContainer)
            try populateStartupData()
            try? sendAnalytics()
        } catch {
            // Persistent store failed — capture and fall back to an in-memory container.
            SentrySDK.capture(error: error)
            initializationError = error

            do {
                let inMemoryConfig = ModelConfiguration(schema: Schema.minnaSchema, isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(
                    for: Schema.minnaSchema,
                    migrationPlan: DatabaseMigrationPlan.self,
                    configurations: inMemoryConfig
                )
                fileDescriptionWriter = FileDescriptionWriter(modelContainer: modelContainer)
                try? populateStartupData()
            } catch {
                // In-memory container is a last resort with no migration plan or disk I/O,
                // so failure here indicates a schema-level programmer error rather than a
                // recoverable runtime condition.
                fatalError("Failed to initialize in-memory fallback container: \(error)")
            }
        }
    }
    
    private func sendAnalytics() throws {
        let fileCount = (try? context.fetchCount(FetchDescriptor<File>())) ?? 0
        let askMinnaCount = (try? context.fetchCount(FetchDescriptor<Chat>())) ?? 0
        TelemetryWrapper.startup(fileCount: fileCount, askMinnaCount: askMinnaCount)
    }

    private func populateStartupData() throws {
        try populateunfiledFolder()
        try populateAppleProvider()
        try populateMLXProvider()
        
        try context.save()
    }
    
    private func populateunfiledFolder() throws {
        let uuid = unfiledFolderUUID
        var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1

        guard try context.fetch(descriptor).isEmpty else { return }
        let unfiledFolder = Folder(uuid: unfiledFolderUUID, name: "Unfiled", icon: FolderIcon(symbol: .symbol(SFSymbol.trayFull.rawValue), color: .champagne), protected: true)
        context.insert(unfiledFolder)
    }
    
    public func unfiledFolder() -> Folder {
        let uuid = unfiledFolderUUID
        var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1
        
        if let folder = try? context.fetch(descriptor).first {
            return folder
        }
        
        let unfiledFolder = Folder(uuid: unfiledFolderUUID, name: "Unfiled", icon: FolderIcon(symbol: .symbol(SFSymbol.trayFull.rawValue), color: .champagne), protected: true)
        context.insert(unfiledFolder)
        return unfiledFolder
    }
    
    private func populateAppleProvider() throws {
        // Make sure we can even add the apple foundation model
        guard SystemLanguageModel.default.availability == .available else { return }
        
        // Check to see if we have already inserted it into the models.
        var descriptor = FetchDescriptor<ConfiguredProvider>(predicate: #Predicate { provider in
            provider.providerID == "apple"
        })
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else { return }
        
        // Add the model
        let appleProvider = ConfiguredProvider(name: "Apple Foundation Models", providerID: "apple")
        context.insert(appleProvider)
    }
    
    private func populateMLXProvider() throws {
        // Check to see if we have already inserted it into the models.
        var descriptor = FetchDescriptor<ConfiguredProvider>(predicate: #Predicate { provider in
            provider.providerID == "mlx"
        })
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else { return }
        
        // Add the model
        let mlxProvider = ConfiguredProvider(name: "On-device MLX", providerID: "mlx")
        context.insert(mlxProvider)
    }
    
    public func queueDescriptionUpdate(for file: File) {
        let persistentID = file.persistentModelID
        let writer = fileDescriptionWriter

        // Route through the queue so bulk imports don't spawn one unbounded
        // task per file (each running Apple Intelligence inference simultaneously).
        indexingQueue.enqueue {
            do {
                try await writer.generateDescription(for: persistentID)
            } catch {
                SentrySDK.capture(error: error)
            }
        }
    }
}
