//
//  Utilities.swift
//  Minna
//
//  Created by Taylor Lineman on 6/17/26.
//

import Foundation
import UniformTypeIdentifiers

struct Utilities {
    enum ASError: Error {
        case supportDirectoryDoesNotExist
    }
    
    public static func tmp() throws -> URL {
        let tmpDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!)
        try FileManager.default.createDirectory(at: tmpDirectory, withIntermediateDirectories: true)
        
        return tmpDirectory
    }
    
    public static func crashLogs() -> URL {
        return FileManager.default.homeDirectoryForCurrentUser.appending(components: "Library", "Logs", "DiagnosticReports")
    }
    
    public static func irisDBDirectory() -> URL {
        return URL.applicationSupportDirectory.appendingPathComponent("search", conformingTo: .directory)
    }

    public static func openGraphCache() -> URL {
        return URL.applicationSupportDirectory.appendingPathComponent("OpenGraphCache", conformingTo: .json)
    }
    
    public static func recordingsDirectory() -> URL {
        return URL.applicationSupportDirectory.appendingPathComponent("meetings", conformingTo: .directory)
    }
    
    public static func savedTranscripts() -> URL {
        return URL.applicationSupportDirectory.appendingPathComponent("transcripts", conformingTo: .directory)
    }
    
}
