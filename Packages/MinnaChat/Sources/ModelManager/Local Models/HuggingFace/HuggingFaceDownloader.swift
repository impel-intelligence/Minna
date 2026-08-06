//
//  HuggingFaceDownloader.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/6/26.
//

import Foundation
import HuggingFace

final class HuggingFaceDownloader: Sendable, Downloader {
    enum HuggingFaceError: Error {
        case invalidCache
    }
    
    let client: HubClient

    public init() {
        client = HubClient(cache: HubCache.minnaCache)
    }

    public func listModels() throws -> [DownloadedModel] {
        guard let hubLocation = HubCache.minnaCache.locationProvider.resolve() else { return [] }
        print(hubLocation)
        return []
    }
    
    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
        let repoID = Repo.ID(stringLiteral: id)
        guard let hubLocation = HubCache.minnaCache.locationProvider.resolve() else {
            throw HuggingFaceError.invalidCache
        }
        let modelDirectory = hubLocation.appending(path: id.replacingOccurrences(of: "/", with: "-"))

        return AsyncThrowingStream<Progress, Error>(bufferingPolicy: .unbounded) { continuation in
            let client = client

            let task = Task {
                do {
                    let modelDir = try await client.downloadSnapshot(
                        of: repoID,
                        to: modelDirectory,
                        matching: ["*.safetensors", "*.json", "*.jinja"],  // Only download what you need
                        progressHandler: { progress in
                            continuation.yield(progress)
                        }
                    )

                    print("Model downloaded to \(modelDir)")
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { [weak self] _ in
                task.cancel()

                Task { @MainActor in
//                    self?.downloading.removeValue(forKey: repoID)
                }
            }
        }
    }
}
