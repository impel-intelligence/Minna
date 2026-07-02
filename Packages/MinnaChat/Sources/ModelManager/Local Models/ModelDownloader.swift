////
////  Downloader.swift
////  MinnaChat
////
////  Created by Taylor Lineman on 6/29/26.
////
//
//import Foundation
//import HuggingFace
//import DatabaseSchema
//import FoundationModels
//
//public enum ModelDownloaderError: Error {
//    case alreadyDownloading
//}
//
//@MainActor @Observable
//public final class ModelDownloader {
//    private var downloading: [ChatModel.ID: AsyncThrowingStream<Progress, Error>] = [:]
//
//    public init() { }
//    
//    func downloadModel(model: ChatModel) throws -> AsyncThrowingStream<Progress, Error> {
//        switch model.source {
//        case .apple:
//            // TODO: Apple has no download functions so just ignore it for now.
//            return AsyncThrowingStream() { _ in }
//        case .huggingFace:
//            return try HuggingFaceDownloader().downloadModel(model: model)
//        }
//    }
//}
