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
    private func loadProviderItem(provider: NSItemProvider, for type: UTType, options: NSDictionary?) async -> URL? {
        await withCheckedContinuation { continuation in
            // MAYBE: Pass the progress that is retrieved here backwards so the user can see the import process
            _ = provider.loadFileRepresentation(for: type, openInPlace: true) { url, wasOpenedInPlace, error in
                guard error == nil, let fileURL = url else {
                    Log.logger.error("Failed to access dropped item", error: error)
                    continuation.resume(returning: nil)
                    return
                }
                
                if wasOpenedInPlace {
                    continuation.resume(returning: fileURL)
                } else {
                    Log.logger.warning("Was not able to open \(fileURL) in place")
                    continuation.resume(returning: fileURL)
                }
            }
        }
    }
    
    func standardDropDestination(presented: Binding<Bool>, selectedFolder: Folder?, modelContext: ModelContext, irisContext: IrisContext, database: Database) -> some View {
        self
            .dropDestination(for: URL.self) { urls, session in
                var scopedURLs: [URL] = []
                
                for url in urls {
                    do {
                        // OKAY LISTEN UP
                        // This is a workaround to get security scoped URLs out of a drop destination. By default macOS (and maybe iOS) do not allow you to get security scoped URLs within a drop session. This is because drop sessions are intended to be a form of IPC. When performing IPC you don't really want another app to be able to jump into another app's storage.
                        // One thing the system does give us is a URL that is resolvable to a bookmark. If we resolve the bookmark with security scope options, and then immediately reconstruct it, we get access to an actual URL that we can use the same as a url from a file importer.
                        // This is most definitely a hack / workaround. There is a chance this breaks in future versions of the app. In that case we need to prompt the user to open URLs that can't be security scoped using a file importer with its starting file set to the URL we retrieve here.
                        let data = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: [.contentTypeKey, .isDirectoryKey])
                        var isStale: Bool = false

                        guard let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else { throw SecurityScopeError.unableToCreateSecurityScope }

                        scopedURLs.append(url)
                    } catch {
                        // TODO: Tell the user and have them use the file selector.
                        Log.logger.error("Failed to gain security scope for \(url)", error: error)
                    }
                }
                
                do {
                    try importURLs(scopedURLs, selectedFolder: selectedFolder, modelContext: modelContext, irisContext: irisContext, database: database)
                } catch {
                    Log.logger.error("Failed to import urls in a drop session", error: error)
                }
            }
    }
    
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
          // Capture the unfiled UUID so the predicate operates (it needs local state)
          let unfiledUUID = database.unfiledFolderUUID
          var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == unfiledUUID })
          descriptor.fetchLimit = 1
          let folders = try modelContext.fetch(descriptor)
          guard let unfiledFolder = folders.first else {
              Log.logger.error("Failed to find the unfiled folder.")
              return
          }
          folder = unfiledFolder
        }

        // Track URLs inserted so we do not insert any duplicates.
        var insertedURLs: Set<URL> = []
                  
        var insertedFiles: [File] = []

        for url in urls {
          let gotAccess = url.startAccessingSecurityScopedResource()
          defer { url.stopAccessingSecurityScopedResource() }
          guard gotAccess else {
              Log.logger.error("Failed to gain security scope for \(url)")
              continue
          }
          
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
                      Log.logger.info("Skipping \(file.url) because it has already been imported.")
                      continue
                  }
                  
                  insertedFiles.append(file)
                  modelContext.insert(file)
              }
          } catch {
              SentrySDK.capture(error: error)
              Log.logger.error("Failed to create file", error: error, metadata: ["url": "\(url)"])
          }
        }

        // Make sure the database is fully saved so service tasks can access files.
        try modelContext.save()

        // Run service tasks. These are both async, they will dispatch their own tasks within.
        for file in insertedFiles {
          Log.logger.info("Inserting \(file.title) into search database.")
          try irisContext.insert(file)
          database.queueDescriptionUpdate(for: file)
        }
    }
}
