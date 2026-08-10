//
//  CDN.swift
//  ModelUploader
//
//  Created by Taylor Lineman on 8/10/26.
//

import Foundation
import Subprocess

struct CDN {
    static let googleBucket = "gs://minna_embedding_models"
    static let cdnDomain = URL(string: "https://cdn.tryminna.com")!
    static let manifest = "manifest.json"

    static func deleteFromCDN(file: String) async throws {
        let deleteURL = googleBucket + "/" + file
        let arguments: Arguments = ["storage", "rm", deleteURL]
        let config: Subprocess.Configuration = .init(.path("/opt/homebrew/bin/gcloud"), arguments: arguments)
        
        _ = try await Subprocess.run(config, output: .currentStandardOutput, error: .combinedWithOutput)
    }
    
    static func downloadFromCDN(file: String, to url: URL) async throws {
        let downloadURL = googleBucket + "/" + file
        let arguments: Arguments = ["storage", "cp", downloadURL, url.absoluteString]
        let config: Subprocess.Configuration = .init(.path("/opt/homebrew/bin/gcloud"), arguments: arguments)
        
        _ = try await Subprocess.run(config, output: .currentStandardOutput, error: .combinedWithOutput)
    }
    
    static func uploadToCDN(file: URL) async throws {
        let arguments: Arguments = ["storage", "cp", file.absoluteString, googleBucket]
        let config: Subprocess.Configuration = .init(.path("/opt/homebrew/bin/gcloud"), arguments: arguments)
        
        _ = try await Subprocess.run(config, output: .currentStandardOutput, error: .combinedWithOutput)
    }
}
