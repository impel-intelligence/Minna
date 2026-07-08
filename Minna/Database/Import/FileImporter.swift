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

extension View {
    func standardFileImporter(presented: Binding<Bool>, selectedFolder: Folder?, modelContext: ModelContext, irisContext: IrisContext, database: Database) -> some View {
        self
            .fileDialogMessage("Pick a file to add to Minna.")
            .fileDialogCustomizationID(MinnaFileDialog.main)
            .fileImporter(isPresented: presented, allowedContentTypes: DigesterFactory.availableUniformTypes + [.directory, .folder], allowsMultipleSelection: true) { result in
                // TODO: Move this off of the main thread to improve import performance.
                do {
                    guard irisContext.isConnected() else {
                        print("You must connect an IrisDB instance on the view!")
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
                    
                    let selectedURLs = try result.get()
                    
                    var insertedFiles: [File] = []
                    
                    for url in selectedURLs {
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
                            print("Failed to create file for \(url): \(error)")
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
                } catch {
                    SentrySDK.capture(error: error)
                    print(error)
                }
            }
    }
}
