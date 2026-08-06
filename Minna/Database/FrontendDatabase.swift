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

    private static let unfilledFolderKey: String = "unfilled_folder_key"
        
    // Swift Data Variables
    let modelContainer: ModelContainer
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    var unfilledFolderUUID: UUID

    private let fileDescriptionWriter: FileDescriptionWriter

    private let indexingQueue: RateLimitedQueue = RateLimitedQueue()

    init() {
        if let uuidString = UserDefaults.standard.object(forKey: FrontendDatabase.unfilledFolderKey) as? String, let uuid = UUID(uuidString: uuidString) {
            unfilledFolderUUID = uuid
        } else {
            unfilledFolderUUID = UUID()
            UserDefaults.standard.set(unfilledFolderUUID.uuidString, forKey: FrontendDatabase.unfilledFolderKey)
        }

        let modelConfiguration = ModelConfiguration(schema: Schema.minnaSchema)
        
        do {
            modelContainer = try ModelContainer(
                for: Schema.minnaSchema,
                migrationPlan: DatabaseMigrationPlan.self,
                configurations: modelConfiguration
            )
            fileDescriptionWriter = FileDescriptionWriter(modelContainer: modelContainer)
            try populateStartupData()
        } catch {
            SentrySDK.capture(error: error)
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func populateStartupData() throws {
        try populateUnfilledFolder()
        try populateAppleProvider()
        try populateMLXProvider()
        
        try context.save()
    }
    
    private func populateUnfilledFolder() throws {
        let uuid = unfilledFolderUUID
        var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1

        guard try context.fetch(descriptor).isEmpty else { return }
        let unfilledFolder = Folder(uuid: unfilledFolderUUID, name: "Unfilled", icon: FolderIcon(symbol: .symbol(SFSymbol.trayFull.rawValue), color: .champagne), protected: true)
        context.insert(unfilledFolder)
    }
    
    public func unfilledFolder() -> Folder {
        let uuid = unfilledFolderUUID
        var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1
        
        if let folder = try? context.fetch(descriptor).first {
            return folder
        }
        
        let unfilledFolder = Folder(uuid: unfilledFolderUUID, name: "Unfilled", icon: FolderIcon(symbol: .symbol(SFSymbol.trayFull.rawValue), color: .champagne), protected: true)
        context.insert(unfilledFolder)
        return unfilledFolder
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
