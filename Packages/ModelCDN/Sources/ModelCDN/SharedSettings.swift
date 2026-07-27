//
//  SharedSettings.swift
//  ModelCDN
//
//  Created by Taylor Lineman on 7/27/26.
//

import Foundation
import BackgroundAssets

public struct ManifestSharedSettings {
    
    public static let appGroupIdentifier = {
        guard let infoDictionary = Bundle.main.infoDictionary, let identifier = infoDictionary["AppGroupIdentifier"] as? String else {
            return "group.com.tryminna"
        }

        return identifier
    }()

    public static let sharedResourcesURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
    
    public static let modelStorageURL = {
        let url = sharedResourcesURL.appending(components: "Library", "Caches", "Models", directoryHint: .isDirectory)
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            fatalError("Failed to create session storage directory: \(error)")
        }
        
        return url
    }()
    
    public static let localManifestURL = modelStorageURL.appending(path: "manifest.json")
}
