//
//  Database.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftData
import Foundation

@MainActor
class FrontendDatabase {
    static let shared: FrontendDatabase = FrontendDatabase()

    private static let unfilledFolderKey: String = "unfilled_folder_key"
        
    let modelContainer: ModelContainer
    var unfilledFolderUUID: UUID
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
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
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try populateStartupData()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func populateStartupData() throws {
        let descriptor = FetchDescriptor<Folder>()
        guard try context.fetch(descriptor).isEmpty else { return }
        let unfilledFolder = Folder(uuid: unfilledFolderUUID, name: "Unfilled", icon: FolderIcon(symbol: .symbol("tray.full")), protected: true)
        context.insert(unfilledFolder)
        try context.save()
    }
}
