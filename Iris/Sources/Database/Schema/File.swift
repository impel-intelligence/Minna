//
//  File.swift
//  Iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import Foundation
import SwiftData
import SFSymbols
import SwiftUI
import ViewStorage
import UniformTypeIdentifiers

enum SecurityScopeError: Error {
    case noBookmarkData
    case unableToCreateSecurityScope
}

@Model
final class File {
    @Attribute(.unique) 
    var uuid: UUID
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Folder.files)
    var folder: Folder
    
    var title: String
    var shortDescription: String
    var color: ThemeColor
    @Attribute(.unique) var url: URL
    var bookmark: Data?
    var type: ContentType = ContentType.webpage
    var source: String

    init(uuid: UUID = UUID(), createdAt: Date, folder: Folder, title: String, shortDescription: String, color: ThemeColor, type: ContentType, url: URL, bookmark: Data?, source: String) {
        self.uuid = uuid
        self.createdAt = createdAt
        self.folder = folder
        self.title = title
        self.shortDescription = shortDescription
        self.color = color
        self.type = type
        self.bookmark = bookmark
        self.url = url
        self.source = source
    }
}

extension File {
    static func generateBookmarkData(for url: URL) throws -> Data {
        return try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: [.contentTypeKey, .isDirectoryKey])
    }
    
    /// Create a security scoped URL if a bookmark exists. If a bookmark does not exist, an error will be thrown.
    /// - Returns: A Security Scoped URL.
    @MainActor
    func securityScopedURL() throws -> URL {
        guard let bookmark = self.bookmark else { throw SecurityScopeError.noBookmarkData }
        
        var isStale: Bool = false

        guard let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else { throw SecurityScopeError.unableToCreateSecurityScope }
        
        if isStale {
            // Update the model with the new bookmark data
            self.bookmark = try File.generateBookmarkData(for: url)
            
            // Save the updated model in the frontend database.
            guard let modelContext = self.modelContext else {
                print("Failed to get file model context \(uuid)")
                return url
            }
            modelContext.insert(self)
        }
        
        return url
    }
}
