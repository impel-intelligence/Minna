//
//  FileImporter.swift
//  Iris
//
//  Created by Taylor Lineman on 6/17/26.
//

import SwiftData
import SwiftUI
import Digester

extension View {
    func standardFileImporter(presented: Binding<Bool>, selectedFolder: Folder?, modelContext: ModelContext, irisContext: IrisContext) -> some View {
        self
            .fileDialogMessage("Pick a file to add to Iris.")
            .fileDialogCustomizationID(IrisFileDialog.main)
            .fileImporter(isPresented: presented, allowedContentTypes: DigesterFactory.availableUniformTypes + [.directory, .folder], allowsMultipleSelection: true) { result in
                do {
                    guard irisContext.isConnected() else {
                        print("You must connect an IrisDB instance.")
                        return
                    }
                    
                    var folder: Folder
                    
                    if let selectedFolder {
                        folder = selectedFolder
                    } else {
                        // Capture the unfilled UUID so the predicate operates (it needs local state)
                        let unfilledUUID = FrontendDatabase.shared.unfilledFolderUUID
                        var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == unfilledUUID })
                        descriptor.fetchLimit = 1
                        let folders = try modelContext.fetch(descriptor)
                        guard let unfilledFolder = folders.first else { return }
                        folder = unfilledFolder
                    }
                    
                    // Track URLs inserted so we do not insert any duplicates.
                    var insertedURLs: Set<URL> = []
                    
                    let files = try result.get()
                    
                    for file in files {
                        let gotAccess = file.startAccessingSecurityScopedResource()
                        guard gotAccess else { return }
                        
                        do {
                            // URL may be a directory, so this can return many urls.
                            let files = try FileFactory.files(from: file, in: folder)
                            
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
                                
                                modelContext.insert(file)
                                try irisContext.insert(file)
                                FrontendDatabase.shared.queueDescriptionUpdate(for: file)
                            }
                        } catch {
                            print("Failed to create file for \(file): \(error)")
                        }
                        
                        file.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    print(error)
                }
                
            }
    }
}

