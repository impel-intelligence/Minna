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

@MainActor
class FrontendDatabase {
    static let shared: FrontendDatabase = FrontendDatabase()

    private static let unfilledFolderKey: String = "unfilled_folder_key"
        
    // Swift Data Variables
    let modelContainer: ModelContainer
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    var unfilledFolderUUID: UUID

    private let fileDescriptionWriter: FileDescriptionWriter

    init() {
        if let uuidString = UserDefaults.standard.object(forKey: FrontendDatabase.unfilledFolderKey) as? String, let uuid = UUID(uuidString: uuidString) {
            unfilledFolderUUID = uuid
        } else {
            unfilledFolderUUID = UUID()
            UserDefaults.standard.set(unfilledFolderUUID.uuidString, forKey: FrontendDatabase.unfilledFolderKey)
        }

        let schema = Schema([
            File.self,
            Folder.self,
            FolderIcon.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            fileDescriptionWriter = FileDescriptionWriter(modelContainer: modelContainer)
            try populateStartupData()
            modelContainer.mainContext.undoManager = UndoManager()
        } catch {
            SentrySDK.capture(error: error)
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func populateStartupData() throws {
        let descriptor = FetchDescriptor<Folder>()
        guard try context.fetch(descriptor).isEmpty else { return }
        let unfilledFolder = Folder(uuid: unfilledFolderUUID, name: "Unfilled", icon: FolderIcon(symbol: .symbol(SFSymbol.trayFull.rawValue), color: .champagne), protected: true)
        context.insert(unfilledFolder)
        try context.save()
    }
    
    func queueDescriptionUpdate(for file: File) {
        let persistentID = file.persistentModelID
        let writer = fileDescriptionWriter
        
        Task(name: "Generate description for \(file.title)", priority: .low) {
            try await writer.generateDescription(for: persistentID)
        }
    }
}
