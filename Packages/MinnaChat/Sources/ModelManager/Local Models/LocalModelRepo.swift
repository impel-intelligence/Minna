//
//  LocalModelRepo.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/5/26.
//

import Foundation
import HuggingFace
import ModelCDN
import Hub

protocol Downloader: Sendable {
    func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error>
    func listModels() throws -> [DownloadedModel]
}

public final class LocalModelRepo: Sendable {
    enum RepoError: Error {
        case modelDoesNotExistOnDisk
    }
    
    public static let shared: LocalModelRepo = LocalModelRepo()
    let modelCDNDownloader = ModelCDNDownloader()
    
    private init() { }
    
    public func getModel(id: String) throws -> DownloadedModel {
        guard let model = try modelCDNDownloader.listModels().first(where: { $0.id == id }) else {
            throw RepoError.modelDoesNotExistOnDisk
        }
        
        return model
    }
    
    public func availableModels() throws -> [DownloadedModel] {
        return try modelCDNDownloader.listModels()
    }
}

public final class ModelCDNDownloader: /*Downloader,*/ Sendable {
    public init() { }
    
    public func listModels() throws -> [DownloadedModel] {
        var downloadedModels: [DownloadedModel] = []
                
        let contents = try FileManager.default.contentsOfDirectory(at: ManifestSharedSettings.modelStorageURL, includingPropertiesForKeys: [.isDirectoryKey])
        
        // Loop over every directory
        for directory in contents where ((try? directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false) {
            let directoryID = directory.lastPathComponent
            let directoryContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [])
            
            // If there is .safetensors, and a jinja chat template this is a valid chat model.
            guard directoryContents.contains(where: { $0.pathExtension == "safetensors" }) else { continue }
            guard directoryContents.contains(where: { $0.pathExtension == "jinja" }) else { continue }

            downloadedModels.append(DownloadedModel(id: directoryID, displayName: directoryID, runner: .mlx, directory: directory))
        }
        
        return downloadedModels
    }
    
//    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
//        
//    }
}
