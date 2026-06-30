//
//  Downloader.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/29/26.
//

import Foundation

//public actor ModelDownloader {
//    let client: HubClient
//    
//    init() {
//        let cacheFolder: URL
//        if URL.applicationSupportDirectory.path().contains("Containers") {
//            // If we are in sandboxed application with its own container there is no need to append to the Support Directory.
//            cacheFolder = URL.applicationSupportDirectory.appending(path: "models")
//        } else {
//            // If we are not sandboxed, add a Minna directory then the models cache.
//            cacheFolder = URL.applicationSupportDirectory.appending(path: "Minna").appending(path: "models")
//        }
//        
//        // This will be handled by hugging face later if it fails, its not too big of a deal.
//        try? FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
//
//        print("Cache Folder: \(cacheFolder)")
//
//        let cache = HubCache(location: .fixed(directory: cacheFolder))
//        client = HubClient(cache: cache)
//    }
//    
//    // Edited by Claude Opus 4.8 (Anthropic) on 2026-06-30
//    func downloadModel(id: Repo.ID) -> AsyncThrowingStream<Progress, Error> {
//        AsyncThrowingStream { continuation in
//            let task = Task { [client] in
//                do {
//                    
////                    let repo = Hub.Repo(id: id)
////                    let modelFiles = ["*.safetensors", "*.json", "*.jinja"]
////                    return try await hub.snapshot(
////                        from: repo,
////                        revision: revision,
////                        matching: modelFiles,
////                        progressHandler: progressHandler
////                    )
//
////                    client.downloadSnapshot(of: <#T##Repo.ID#>, localFilesOnly: <#T##Bool#>)
////                    _ = try await client.downloadSnapshot(of: id) { progress in
////                        continuation.yield(progress)
////                    }
//
//                    continuation.finish()
//                } catch {
//                    continuation.finish(throwing: error)
//                }
//            }
//
//            continuation.onTermination = { _ in task.cancel() }
//        }
//    }
//}
