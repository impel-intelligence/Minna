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
                return url
            }
            
            modelContext.insert(self)
        }
        
        return url
    }
}

extension File {
    @MainActor
    public func openOriginal(openURL: OpenURLAction) throws {
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
