////
////  ChatModel+Available.swift
////  MinnaChat
////
////  Created by Taylor Lineman on 6/30/26.
////
//
//import Foundation
//import DatabaseSchema
//import FoundationModels
//import HuggingFace
//
//public enum ModelAvailability {
//    case available
//    case notDownloaded
//    case notAvailable
//    case notSupported
//    case notEnabled
//}
//
//public extension ChatModel {
//    var availability: ModelAvailability {
//        switch source {
//        case .apple:
//            if #available(macOS 26.0, *) {
//                switch SystemLanguageModel.default.availability {
//                case .available:
//                    return .available
//                case .unavailable(.deviceNotEligible):
//                    return .notSupported
//                case .unavailable(.appleIntelligenceNotEnabled):
//                    return .notEnabled
//                case .unavailable(.modelNotReady):
//                    return .notDownloaded
//                case .unavailable(let other):
//                    return .notAvailable
//                }
//            } else {
//                return .notSupported
//            }
//        case .huggingFace:
//            guard let repoID = Repo.ID(rawValue: self.id) else { return .notAvailable }
//            let client = HubClient(cache: HubCache.minnaCache)
//            let directory = HubCache.minnaCache.metadataDirectory(repo: repoID, kind: .model)
//            return FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) ? .available : .notDownloaded
//        }
//    }
//}
