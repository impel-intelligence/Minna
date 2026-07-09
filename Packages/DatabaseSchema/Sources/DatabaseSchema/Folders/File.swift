//
//  File.swift
//  Minna
//
//  Created by Taylor Lineman on 6/11/26.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

public enum SecurityScopeError: Error {
    case noBookmarkData
    case unableToCreateSecurityScope
}

@Model
public final class File {
    @Attribute(.unique)
    public var uuid: UUID
    public var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Folder.files)
    public var folder: Folder
    
    /// There is a SwiftData crash (Unexpected backing data for snapshot creation: SwiftData._FullFutureBackingData<>) when
    /// deleting a model that contains a cascading delete rule when an undo manager is present. The exact crash occurs when
    /// the backing data has not been fully materialized (grabbed from the SQLITE database). This is a recent bug that cropped
    /// up in Xcode 26, and it has a feedback tracking it FB22539495: https://developer.apple.com/forums/thread/822241.
    @Relationship(.unique, deleteRule: .cascade)
    public var chat: Chat? = nil
    
    public var title: String
    public var shortDescription: String
    public var color: ThemeColor
    @Attribute(.unique) public var url: URL
    public var bookmark: Data?
    public var type: ContentType = ContentType.webpage
    public var source: String

    // Background task completion flags. Kept as direct stored properties (rather than a nested
    // Codable struct) so they can be used in SwiftData fetch predicates.
    public var searchIndexed: Bool = false
    public var descriptionGenerated: Bool = false

    public init(uuid: UUID = UUID(), createdAt: Date, folder: Folder, title: String, shortDescription: String, color: ThemeColor, type: ContentType, url: URL, bookmark: Data?, source: String, chat: Chat? = nil) {
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
        self.chat = chat
    }
}

extension File {
    public static func generateBookmarkData(for url: URL) throws -> Data {
        return try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: [.contentTypeKey, .isDirectoryKey])
    }
    
    /// Create a security scoped URL if a bookmark exists. If a bookmark does not exist, an error will be thrown.
    /// - Returns: A Security Scoped URL.
    public func securityScopedURL() throws -> URL {
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

extension File {
    @MainActor
    public func open(openURL: OpenURLAction) throws {
        guard self.url.isFileURL, self.bookmark != nil else {
            openURL(url)
            return
        }
        
        let url = try securityScopedURL()
        guard url.startAccessingSecurityScopedResource() else { return }
        
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            url.stopAccessingSecurityScopedResource()
            if let error {
                print("Failed to open original \(url): \(error)")
            }
        }
    }
}
