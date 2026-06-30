//
//  Downloader.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/29/26.
//

import Foundation
import HuggingFace

public enum ModelDownloaderError: Error {
    case alreadyDownloading
}

@MainActor @Observable
public final class ModelDownloader {
    
    let client: HubClient
    
    private var downloading: [Repo.ID: AsyncThrowingStream<Progress, Error>] = [:]
    
    public init() {
        client = HubClient(cache: HubCache.minnaCache)
    }
    
    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
        let repoID = Repo.ID(stringLiteral: id)
        
        if let inFlightProgress = downloading[repoID] {
            return inFlightProgress
        }
        
        let stream =  AsyncThrowingStream { continuation in
            let client = client

            let task = Task {
                do {
                    let modelDir = try await client.downloadSnapshot(
                        of: repoID,
                        to: HubCache.minnaCacheFolder,
                        matching: ["*.safetensors", "*.json", "*.jinja"],  // Only download what you need
                        progressHandler: { progress in
                            continuation.yield(progress)
                        }
                    )
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { [weak self] _ in
                task.cancel()
                
                Task { @MainActor in
                    self?.downloading.removeValue(forKey: repoID)
                }
            }
        }
        
        downloading[repoID] = stream
        
        return stream
    }
}
