////
////  HuggingFaceDownloader.swift
////  MinnaChat
////
////  Created by Taylor Lineman on 6/30/26.
////
//
//import DatabaseSchema
//import Foundation
//import HuggingFace
//
//final class HuggingFaceDownloader: Downloader, Sendable {
//    let client: HubClient
//        
//    public init() {
//        client = HubClient(cache: HubCache.minnaCache)
//    }
//    
////    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
////        let repoID = Repo.ID(stringLiteral: id)
////        
////        return AsyncThrowingStream { continuation in
////            let client = client
////            
////            let task = Task {
////                do {
////                    let modelDir = try await client.downloadSnapshot(
////                        of: repoID,
////                        to: HubCache.minnaCacheFolder,
////                        matching: ["*.safetensors", "*.json", "*.jinja"],  // Only download what you need
////                        progressHandler: { progress in
////                            continuation.yield(progress)
////                        }
////                    )
////                    
////                    continuation.finish()
////                } catch {
////                    continuation.finish(throwing: error)
////                }
////            }
////            
////            continuation.onTermination = { [weak self] _ in
////                task.cancel()
////                
////                Task { @MainActor in
////                    self?.downloading.removeValue(forKey: repoID)
////                }
////            }
////        }
////    }
//    
//    func downloadModel(model: ChatModel) throws -> AsyncThrowingStream<Progress, any Error> {
//        return AsyncThrowingStream { continuation in
//            continuation.finish()
//        }
//    }
//
//}
