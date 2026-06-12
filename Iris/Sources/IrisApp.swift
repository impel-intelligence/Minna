//
//  IrisApp.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftUI
import SwiftData

@main
struct IrisApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ContentItem.self,
            Folder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try populateStartupData(context: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private static func populateStartupData(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Folder>()
        guard try context.fetch(descriptor).isEmpty else { return }
        let unfilledFolder = Folder(name: "Unfilled", icon: FolderIcon(symbol: .symbol("tray.full")), protected: true)
        context.insert(unfilledFolder)
        try context.save()
    }

    var body: some Scene {
        WindowGroup {
            NavigationCore()
        }
        .modelContainer(sharedModelContainer)
    }
}
