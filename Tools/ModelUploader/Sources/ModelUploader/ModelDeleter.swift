//
//  ModelDeleter.swift
//  ModelUploader
//
//  Created by Taylor Lineman on 8/10/26.
//

import ArgumentParser
import Foundation
import CoreML
import AppleArchive
import System
import Subprocess
import ModelCDN
import CryptoKit

struct ModelDeleter: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "delete", abstract: "Delete models from the CDN.")
    
    @Argument(help: "The identifier of the model to delete.")
    var identifier: String
    
    mutating func run() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appending(path: "model_uploader")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let packageDirectory = temporaryDirectory.appending(path: identifier)
        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: packageDirectory) }
        
                
        print("Retrieving Existing Manifest")
        let manifestFile = temporaryDirectory.appending(path: CDN.manifest)
        try await CDN.downloadFromCDN(file: CDN.manifest, to: manifestFile)
        
        var manifest: Manifest
        if FileManager.default.fileExists(atPath: manifestFile.path(percentEncoded: false)) {
            print("Manifest found!")
            manifest = try Manifest.load(from: manifestFile)
        } else {
            print("No manifest found, creating a new one.")
            manifest = Manifest(files: [])
        }
        
        manifest.files.removeAll(where: { $0.identifier == identifier })
                            
        print("Saving manifest file")
        try manifest.save(to: manifestFile)
        
        print("Uploading Manifest File")
        try await CDN.uploadToCDN(file: manifestFile)
    }
}
