//
//  URLHandler.swift
//  Minna
//
//  Created by Taylor Lineman on 7/9/26.
//

import Foundation
import SwiftData
import DatabaseSchema
import SwiftUI

struct URLHandler {
    enum HandlingError: Error {
        case notAMinnaURL
        case noComponents
        case noActions
        case unsupportedAction
        case canNotGetClearance
    }
    
    enum OpenDocumentActionError: Error {
        case invalidUUID
        case noDocumentWithUUID(uuid: UUID)
    }
    
    /// Handles incoming URLs, performing validation before any actions are taken.
    static func handle(_ url: URL, database: any Database, router: NavigationRouter, openWindow: OpenWindowAction, irisContext: IrisContext) throws {
        if url.scheme == "minna" {
            // If we are a Minna URL process it into our deep-linking architecture.
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw HandlingError.noComponents }
            
            // Ensure that the action we are taking is opening a document
            guard let action = components.host else {
                throw HandlingError.noActions
            }
            
            // Check if this is the docs action.
            if action == "doc" {
                return try handleDocURL(components, context: database.context, router: router, openWindow: openWindow)
            }
            
            // If we never returned from an action, throw an unsupported action error.
            throw HandlingError.unsupportedAction
        } else if url.isFileURL {
            // If we are a file URL add the file into Minna as if it was imported.
            
            
            
//            guard url.startAccessingSecurityScopedResource() else {
//                throw HandlingError.canNotGetClearance
//            }
//            defer { url.stopAccessingSecurityScopedResource() }
//            var folder: Folder
//            
//            // Capture the unfilled UUID so the predicate operates (it needs local state)
//            let unfilledUUID = database.unfilledFolderUUID
//            var folderDescriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == unfilledUUID })
//            folderDescriptor.fetchLimit = 1
//            let folders = try database.context.fetch(folderDescriptor)
//            guard let unfilledFolder = folders.first else { return }
//            folder = unfilledFolder
//
//            // URL may be a directory, so this can return many urls.
//            let files = try FileFactory.files(from: url, in: folder)
//
//            // Local copy of file urls for the search predicate.
//            let urls = files.compactMap({$0.url})
//            
//            // Skip anything already persisted in the store.
//            let fileDescriptor = FetchDescriptor<File>(predicate: #Predicate { urls.contains($0.url) })
//            
//            // Find all of the URLs in this set that already exist in the database.
//            let existingURLs: Set<URL> = Set((try? database.context.fetch(fileDescriptor))?.compactMap({$0.url}) ?? [])
//            
//            var insertedFiles: Set<File> = []
//            
//            for file in files {
//                guard !existingURLs.contains(file.url) else { continue }
//                insertedFiles.insert(file)
//                database.context.insert(file)
//            }
//            
//            // Make sure the database is fully saved so service tasks can access files.
//            try database.context.save()
//            
//            // Run service tasks. These are both async, they will dispatch their own tasks within.
//            for file in insertedFiles {
//                try irisContext.insert(file)
//                database.queueDescriptionUpdate(for: file)
//            }
        }
    }
    
    private static func handleDocURL(_ components: URLComponents, context: ModelContext, router: NavigationRouter, openWindow: OpenWindowAction) throws {
        // Find the UUID of the document we want to open.
        let cleanedPath = components.path.replacingOccurrences(of: "/", with: "")
        guard let uuid = UUID(uuidString: cleanedPath) else {
            throw OpenDocumentActionError.invalidUUID
        }
        
        var descriptor = FetchDescriptor<File>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1
        let folders = try context.fetch(descriptor)
        guard let fileToOpen = folders.first else { throw OpenDocumentActionError.noDocumentWithUUID(uuid: uuid) }
        let openAction = OpenFileAction(id: fileToOpen.persistentModelID)
        
        if let rawExcerpts = components.queryItems?.first(where: {$0.name == "excerpts"})?.value {
            let excerpts = rawExcerpts.split(separator: ",").map(String.init).compactMap(Int.init)
            PreviewWindowParameterStore.shared.setParameters(for: openAction, to: OpenFileParameters(excertps: excerpts))
        }
        
        openWindow(id: PreviewWindow.windowID, value: openAction)

    }
}
