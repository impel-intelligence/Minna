//
//  Database.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftData
import Foundation
import BlurbKit

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

    private var backgroundWorker: BackgroundWorker? = nil
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
            Folder.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            fileDescriptionWriter = FileDescriptionWriter(modelContainer: modelContainer)
            try populateStartupData()
            modelContainer.mainContext.undoManager = UndoManager()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    public func setWorker(_ worker: BackgroundWorker) {
        self.backgroundWorker = worker
    }
    
    private func populateStartupData() throws {
        let descriptor = FetchDescriptor<Folder>()
        guard try context.fetch(descriptor).isEmpty else { return }
        let unfilledFolder = Folder(uuid: unfilledFolderUUID, name: "Unfilled", icon: FolderIcon(symbol: .symbol("tray.full")), protected: true)
        context.insert(unfilledFolder)
        try context.save()
    }
    
    func queueDescriptionUpdate(for file: File) {
        let persistentID = file.persistentModelID
        let writer = fileDescriptionWriter
        
        backgroundWorker?.enqueue(BlockBackgroundTask { [writer, persistentID] in
            try await writer.generateDescription(for: persistentID)
        })
    }
}
