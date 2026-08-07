//
//  File.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 8/7/26.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension SchemaV2 {
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
}

