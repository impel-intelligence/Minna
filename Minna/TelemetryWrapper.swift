//
//  TelemetryWrapper.swift
//  Minna
//
//  Created by Taylor Lineman on 8/6/26.
//

import TelemetryDeck
import Logging

fileprivate extension String {
    static let startup = "startup"
    static let chat = "chat"
    static let open = "didLaunch"
}

final class TelemetryWrapper {
    enum ChatLocation: String {
        case askMinna
        case askDoc
    }
    
    static let shared: TelemetryWrapper = TelemetryWrapper()
    
    var initialized: Bool = false
    
    private init() {
        // Product analytics are opt-in via Config.xcconfig on the same terms.
        guard let appID = BuildConfiguration.telemetryDeckID else {
            Log.logger.warning("Not initializing telemetry: Could not find App ID")
            return
        }
        
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
        initialized = true
    }
        
    /// Used to track daily active users
    func didLaunch() {
        guard initialized else { Log.logger.warning("Telemetry not initialized!"); return }
        TelemetryDeck.signal(.open)
    }
    
    func startup(fileCount: Int, askMinnaCount: Int) {
        guard initialized else { Log.logger.warning("Telemetry not initialized!"); return }
        let payload = [
            "files": "\(fileCount)",
            "askMinna": "\(askMinnaCount)"
        ]
        
        TelemetryDeck.signal(.startup, parameters: payload)
    }
    
    func chat(model: String, location: ChatLocation) {
        guard initialized else { Log.logger.warning("Telemetry not initialized!"); return }
        let payload = [
            "model": model,
            "location": location.rawValue
        ]
        
        TelemetryDeck.signal(.chat, parameters: payload)
    }
}
