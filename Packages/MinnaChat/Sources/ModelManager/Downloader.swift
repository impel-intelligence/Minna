//
//  Downloader.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/29/26.
//

import Foundation
import HuggingFace

public struct ModelDownloader {
    let client: HubClient
    
    init() {
        var cacheFolder = URL.applicationSupportDirectory.appending(path: "models")
        if !cacheFolder.path().contains("Containers") {
            cacheFolder = cacheFolder.appendingPathComponent("Minna", conformingTo: .directory)
        }
        
        // This will be handled by hugging face later if it fails, its not too big of a deal.
        try? FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)

        print("Cache Folder: \(cacheFolder)")

        let cache = HubCache(location: .fixed(directory: cacheFolder))
        client = HubClient(cache: cache)
    }
    
    func downloadModel(id: Repo.ID) async throws {
        let model = try await client.downloadSnapshot(of: id) { progress in
            print(progress)
        }
    }
}
