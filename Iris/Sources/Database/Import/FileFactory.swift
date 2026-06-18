//
//  FileFactory.swift
//  Iris
//
//  Created by Taylor Lineman on 6/17/26.
//

import Foundation
import SwiftData
import BlurbKit

struct FileFactory {
    enum FileFactoryError: Error {
        case unsupportedType
    }
    
    static func files(from url: URL, in folder: Folder) throws -> [File] {
        let fileAttributes = try url.resourceValues(forKeys: [.contentTypeKey, .isDirectoryKey])

        // If we are a directory, iterate through the files within.
        if fileAttributes.isDirectory ?? false {
            var files: [File] = []
            
            if let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.contentTypeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let itemURL as URL in enumerator {
                    let attributes = try itemURL.resourceValues(forKeys: [.contentTypeKey, .isDirectoryKey])
                    guard let file = try? file(from: itemURL, in: folder, resourceValues: attributes) else { continue }
                    files.append(file)
                }
            }
            
            return files
        }
        
        guard let file = try file(from: url, in: folder, resourceValues: fileAttributes) else { return [] }
        
        return [file]
    }
    
    // com.microsoft.word,, com.unknown.md, public.html, org.openxmlformats.wordprocessingml.document
    // org.openxmlformats.presentationml.presentation
    private static func file(from url: URL, in folder: Folder, resourceValues: URLResourceValues) throws -> File? {
        guard let contentType = resourceValues.contentType else { return nil }
        
        guard let irisContentType = ContentType(uniformType: contentType) else {
            print("Unsupported type: \(contentType)")
            throw FileFactoryError.unsupportedType
        }
        
        let bookmarkData = try File.generateBookmarkData(for: url)
        let fileBlurb = try BlurbFactory.provider(for: contentType).blurb(for: url)
        
        return File(createdAt: Date.now, folder: folder, title: fileBlurb.title, shortDescription: fileBlurb.description, color: .random, type: irisContentType, url: url, bookmark: bookmarkData, source: "FileSystem")
    }
}
