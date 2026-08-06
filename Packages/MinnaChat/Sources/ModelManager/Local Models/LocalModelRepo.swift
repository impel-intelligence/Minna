//
//  LocalModelRepo.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/5/26.
//

import Foundation
import HuggingFace
import ModelCDN

protocol Downloader: Sendable {
    func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error>
    func listModels() throws -> [DownloadedModel]
}

public final class LocalModelRepo: Sendable {
    enum RepoError: Error {
        case modelDoesNotExistOnDisk
    }
    
    public static let shared: LocalModelRepo = LocalModelRepo()
    let huggingFaceDownloader = HuggingFaceDownloader()
    
    private init() { }
    
    public func getModel(id: String) -> DownloadedModel {
        return DownloadedModel(id: "", displayName: "", runner: .mlx, directory: URL(filePath: "/"))
    }
    
    public func availableModels() -> [DownloadedModel] {
        return [
            DownloadedModel(id: "qwen3.5-9b", displayName: "Qwen3.5 9B", runner: .mlx, directory: URL(filePath: "/Users/taylorlineman/Library/Containers/com.tryminna.minna/Data/Library/Application Support/models/Qwen3.5-9B-MLX-4bit"))
        ]
    }
    
    public func download(id: String) throws -> AsyncThrowingStream<Progress, Error> {
        return try huggingFaceDownloader.downloadModel(id: id)
    }
}

//public final class ModelCDNDownloader: /*Downloader,*/ Sendable {
//    public init() { }
//    
//    public func listModels() throws -> [DownloadedModel] {
//        let contents = try FileManager.default.contentsOfDirectory(at: ManifestSharedSettings.modelStorageURL, includingPropertiesForKeys: [.isDirectoryKey])
//        
//        print(contents)
//        
//        return []
//    }
//    
////    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
////        
////    }
//}
