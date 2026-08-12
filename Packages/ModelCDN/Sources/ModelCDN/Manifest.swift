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
    case iOS
    case tvOS
    case watchOS
    case visionOS
    case linux
    case windows
    
    public func matches() -> Bool {
        #if os(iOS)
        return self == .iOS
        #elseif os(macOS)
        return self == .macOS
        #elseif os(tvOS)
        return self == .tvOS
        #elseif os(watchOS)
        return self == .watchOS
        #elseif os(visionOS)
        return self == .visionOS
        #elseif os(Linux)
        return self == .linux
        #elseif os(Windows)
        return self == .windows
        #endif
    }
}

public enum ModelType: String, Codable, Sendable {
    case embedding
    case inference
}

public struct Manifest: Codable {
    public struct File: Codable, Sendable, Hashable, Equatable {
        public let identifier: String
        public let name: String
        public let fileSize: Int
        public let url: URL
        public let platforms: [Platform]
        public let required: Bool
        public let hash: String
        
        public var type: ModelType
        
        public init(identifier: String, name: String, fileSize: Int, url: URL, platforms: [Platform], required: Bool, hash: String, type: ModelType) {
            self.identifier = identifier
            self.fileSize = fileSize
            self.url = url
            self.platforms = platforms
            self.required = required
            self.hash = hash
            self.name = name
            self.type = type
        }
        
        public init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<Manifest.File.CodingKeys> = try decoder.container(keyedBy: Manifest.File.CodingKeys.self)
            self.identifier = try container.decode(String.self, forKey: Manifest.File.CodingKeys.identifier)
            self.name = try container.decode(String.self, forKey: Manifest.File.CodingKeys.name)
            self.fileSize = try container.decode(Int.self, forKey: Manifest.File.CodingKeys.fileSize)
            self.url = try container.decode(URL.self, forKey: Manifest.File.CodingKeys.url)
            self.platforms = try container.decode([Platform].self, forKey: Manifest.File.CodingKeys.platforms)
            self.required = try container.decode(Bool.self, forKey: Manifest.File.CodingKeys.required)
            self.hash = try container.decode(String.self, forKey: Manifest.File.CodingKeys.hash)
            
            // Default value for type.
            self.type = (try? container.decode(ModelType.self, forKey: Manifest.File.CodingKeys.type)) ?? ModelType.embedding
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
