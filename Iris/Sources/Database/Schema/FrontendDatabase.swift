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
    private let descriptionUpdateQueue: WorkQueue = WorkQueue()

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
    
    func queueDescriptionUpdate(for file: File) {
        Task {
            await descriptionUpdateQueue.enqueue {
                let url = try file.securityScopedURL()
                guard let contentType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                    print("Failed to get content type for file \(file)")
                    return
                }
                
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                
                guard hasAccess else {
                    print("Unable to obtain security scope")
                    return
                }
                
                let blurbProvider = try BlurbFactory.provider(for: contentType)
                // Retrieve a file blurb using Apple's Intelligence models.
                let blurb = try await blurbProvider.blurb(for: url)
                file.shortDescription = blurb.description
                file.modelContext?.insert(file)
            }
        }
    }
}
