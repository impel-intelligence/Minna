////
////  HubCache+Extension.swift
////  MinnaChat
////
////  Created by Taylor Lineman on 6/30/26.
////
//
//import Foundation
//import HuggingFace
//
//public extension HubCache {
//    static var minnaCacheFolder: URL {
//        if URL.applicationSupportDirectory.path().contains("Containers") {
//            // If we are in sandboxed application with its own container there is no need to append to the Support Directory.
//            return URL.applicationSupportDirectory.appending(path: "models")
//        } else {
//            // If we are not sandboxed, add a Minna directory then the models cache.
//            return URL.applicationSupportDirectory.appending(path: "Minna").appending(path: "models")
//        }
//    }
//    
//    static var minnaCache: HubCache {
//        return HubCache(location: .fixed(directory: minnaCacheFolder))
//    }
//}
