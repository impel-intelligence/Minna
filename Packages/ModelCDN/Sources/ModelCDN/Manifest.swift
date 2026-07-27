//
//  Manifest.swift
//  ModelUploader
//
//  Created by Taylor Lineman on 7/24/26.
//

import Foundation
import BackgroundAssets

public enum Platform: String, Codable, Sendable {
    case macOS
}

public struct Manifest: Codable {
    public struct File: Codable, Sendable {
        public let identifier: String
        public let fileSize: Int
        public let url: URL
        public let platforms: [Platform]
        public let required: Bool
        public let hash: String
        
        public init(identifier: String, fileSize: Int, url: URL, platforms: [Platform], required: Bool, hash: String) {
            self.identifier = identifier
            self.fileSize = fileSize
            self.url = url
            self.platforms = platforms
            self.required = required
            self.hash = hash
        }
    }
    
    public var files: [File]
    
    public init(files: [File]) {
        self.files = files
    }
    
    public static func load(from url: URL) throws -> Manifest {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Manifest.self, from: data)
    }
    
    public func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }
}
