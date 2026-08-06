//
//  TelemetryWrapper.swift
//  Minna
//
//  Created by Taylor Lineman on 8/6/26.
//

import PostHog

fileprivate extension String {
    static let startup = "startup"
    static let chat = "chat"
}

struct TelemetryWrapper {
    enum ChatLocation: String {
        case askMinna
        case askDoc
    }
    
    static func startup(fileCount: Int, askMinnaCount: Int) {
        let payload = [
            "files": fileCount,
            "askMinna": askMinnaCount
        ]
        
        PostHogSDK.shared.capture(.startup, properties: payload)
    }
    
    static func chat(model: String, location: ChatLocation) {
        let payload = [
            "model": model,
            "location": location.rawValue
        ]
        
        PostHogSDK.shared.capture(.chat, properties: payload)
    }
}

