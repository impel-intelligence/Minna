//
//  FileImporter.swift
//  Minna
//
//  Created by Taylor Lineman on 6/17/26.
//

import SwiftData
import SwiftUI
import Digester
import SentrySwift
import UniformTypeIdentifiers
import DatabaseSchema
import Logging

extension View {
//    func standardDropDestination(presented: Binding<Bool>, selectedFolder: Folder?, modelContext: ModelContext, irisContext: IrisContext, database: Database) -> some View {
//        self
//            .onDrop(of: [.fileURL], isTargeted: presented) { providers in
//                for provider in providers {
//                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
//                        guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
//                        
//                        if url.hasDirectoryPath {
//                            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.contentTypeKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
//                                let urls = enumerator.allObjects.compactMap { $0 as? URL }
//                                
//                                
//                                do {
//                                    try importURLs(urls, selectedFolder: selectedFolder, modelContext: modelContext, irisContext: irisContext, database: database)
//                                } catch {
//                                    SentrySDK.capture(error: error)
//                                    Log.logger.error("Failed to import files", error: error)
//                                }
////
////                                for case let fileURL as URL in enumerator {
////                                }
//                            }
//                        } else {
////                            do {
////                                let selectedURLs = try result.get()
////                                try importURLs(selectedURLs, selectedFolder: selectedFolder, modelContext: modelContext, irisContext: irisContext, database: database)
////                            } catch {
////                                SentrySDK.capture(error: error)
////                                Log.logger.error("Failed to import files", error: error)
////                            }
//
//                        }
//                    }
//                }
//                
//                return true
//            }
//
//    }
    
    func standardFileImporter(presented: Binding<Bool>, selectedFolder: Folder?, modelContext: ModelContext, irisContext: IrisContext, database: Database) -> some View {
        self
            .fileDialogMessage("Pick a file to add to Minna.")
            .fileDialogCustomizationID(MinnaFileDialog.main)
            .fileImporter(isPresented: presented, allowedContentTypes: DigesterFactory.availableUniformTypes + [.directory, .folder], allowsMultipleSelection: true) { result in
                // TODO: Move this off of the main thread to improve import performance.
                do {
                    let selectedURLs = try result.get()
                    try importURLs(selectedURLs, selectedFolder: selectedFolder, modelContext: modelContext, irisContext: irisContext, database: database)
                } catch {
                    SentrySDK.capture(error: error)
                    Log.logger.error("Failed to import files", error: error)
                }
            }
    }
    
    private func importURLs(_ urls: [URL], selectedFolder: Folder?, modelContext: ModelContext, irisContext: IrisContext, database: Database) throws {
        guard irisContext.isConnected() else {
            Log.logger.error("You must connect an IrisDB instance on the view!")
            SentrySDK.capture(message: "IrisDB instance was not connected.")
            return
        }
        
        var folder: Folder
        
        if let selectedFolder {
            folder = selectedFolder
        } else {
            // Capture the unfilled UUID so the predicate operates (it needs local state)
            let unfilledUUID = database.unfilledFolderUUID
            var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == unfilledUUID })
            descriptor.fetchLimit = 1
            let folders = try modelContext.fetch(descriptor)
            guard let unfilledFolder = folders.first else { return }
            folder = unfilledFolder
        }
        
        // Track URLs inserted so we do not insert any duplicates.
        var insertedURLs: Set<URL> = []
                    
        var insertedFiles: [File] = []
        
        for url in urls {
            let gotAccess = url.startAccessingSecurityScopedResource()
            guard gotAccess else { return }
            
            do {
                // URL may be a directory, so this can return many urls.
                let files = try FileFactory.files(from: url, in: folder)
                
                // Local copy of file urls for the search predicate.
                let urls = files.compactMap({$0.url})
                
                // Skip anything already persisted in the store.
                let descriptor = FetchDescriptor<File>(predicate: #Predicate { urls.contains($0.url) })
                
                // Find all of the URLs in this set that already exist in the database.
                let existingURLs: Set<URL> = Set((try? modelContext.fetch(descriptor))?.compactMap({$0.url}) ?? [])
                insertedURLs = insertedURLs.union(existingURLs)
                
                for file in files {
                    // Skip anything we've already inserted into the database.
                    guard !insertedURLs.contains(file.url) else {
                        continue
                    }
                    
                    insertedFiles.append(file)
                    modelContext.insert(file)
                }
            } catch {
                SentrySDK.capture(error: error)
                Log.logger.error("Failed to create file", error: error, metadata: ["url": "\(url)"])
            }
            
            url.stopAccessingSecurityScopedResource()
        }
        
        // Make sure the database is fully saved so service tasks can access files.
        try modelContext.save()
        
        // Run service tasks. These are both async, they will dispatch their own tasks within.
        for file in insertedFiles {
            try irisContext.insert(file)
            database.queueDescriptionUpdate(for: file)
        }

    }
}
