//
//  HuggingFaceDownloader.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

import DatabaseSchema
import Foundation
import HuggingFace

actor HuggingFaceModelList {
    static let fileName: String = "model_list.json"
    static let filePath: URL = HubCache.minnaCacheFolder.appendingPathComponent(HuggingFaceModelList.fileName, conformingTo: .json)

    var availableModels: [String] = []

    init() {
        do {
            availableModels = try Self.loadFromFile()
        } catch {
            print("Failed to get avialable models \(availableModels)")
        }
    }

    func saveModel(id: String) throws {
        availableModels.append(id)
        try saveFile()
    }

    private static func loadFromFile() throws -> [String] {
        let data = try Data(contentsOf: HuggingFaceModelList.filePath, options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        guard let models = jsonResult as? [String] else { return [] }
        return models
    }
    
    private func saveFile() throws {
        let data = try JSONSerialization.data(withJSONObject: availableModels)
        try data.write(to: HuggingFaceModelList.filePath)
    }
}

public final class HuggingFaceDownloader: Sendable {
    let client: HubClient
    let modelList: HuggingFaceModelList = HuggingFaceModelList()
        
    public init() {
        // Disable Xet's multipathing as Apple's Sandbox breaks it.
        client = HubClient(cache: HubCache.minnaCache, xetTuningConfig: XetTuning(enableMultipath: false))
    }
    
    public func directoryFor(id: String) -> URL {
        return HubCache.minnaCacheFolder.appending(path: id)
    }
    
    public func availableModels() async -> [String] {
        return await modelList.availableModels
    }
    
    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
        let repoID = Repo.ID(stringLiteral: id)
        
        return AsyncThrowingStream { continuation in
            let client = client
            
            let task = Task {
                do {
                    _ = try await client.downloadSnapshot(
                        of: repoID,
                        to: HubCache.minnaCacheFolder.appending(path: id),
                        matching: ["*.safetensors", "*.json", "*.jinja"],  // Only download what you need
                        progressHandler: { progress in
                            continuation.yield(progress)
                        }
                    )
                                        
                    try await modelList.saveModel(id: id)
                    
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
