//
//  Database.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftData

@MainActor
class Database {
    static let shared = Database()
        
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init(sampleData: Bool = false) {
        let schema = Schema([
            File.self,
            Folder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try populateStartupData()
//            print(modelConfiguration.url)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func populateStartupData() throws {
        let descriptor = FetchDescriptor<Folder>()
        guard try context.fetch(descriptor).isEmpty else { return }
        let unfilledFolder = Folder(name: "Unfilled", icon: FolderIcon(symbol: .symbol("tray.full")), protected: true)
        context.insert(unfilledFolder)
        try context.save()
    }
}

