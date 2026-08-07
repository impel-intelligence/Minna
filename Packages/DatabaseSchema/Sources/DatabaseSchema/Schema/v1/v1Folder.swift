//
//  Folder.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 8/7/26.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension SchemaV1 {
    @Model
    public final class FolderIcon {
        public enum Symbol: Codable, Hashable {
            case symbol(String) // TODO: Switch to SFSymbol once that supports codable
            case emoji(String)
            
            var text: String {
                switch self {
                case .symbol(let name):
                    return name
                case .emoji(let string):
                    return string
                }
            }
        }
        
        public var symbol: Symbol
        public var color: ThemeColor
        
        public init(symbol: Symbol, color: ThemeColor) {
            self.symbol = symbol
            self.color = color
        }
    }
}

extension SchemaV1 {
    @Model
    public final class Folder: Identifiable, Hashable {
        @Attribute(.unique)
        public var uuid: UUID
        public var name: String
        public var icon: FolderIcon
        public var protected: Bool = false
        public var order: Int = 0
        
        @Relationship(deleteRule: .nullify) public var children: [Folder]
        @Relationship(deleteRule: .nullify, inverse: \Folder.children) public var parent: Folder?
        
        @Relationship(deleteRule: .cascade) public var files: [File]
        
        /// SwiftData materializes an optional to-many relationship as an empty array `[]`
        /// rather than `nil` once the object is realized by the context. `OutlineGroup`
        /// treats a non-nil (but empty) children array as a collapsible branch, which draws
        /// a disclosure indicator on leaf folders. Expose `nil` for the empty case so leaves
        /// render without one.
        ///
        /// Attribution: Claude Opus 4.8
        public var displayChildren: [Folder]? {
            guard !children.isEmpty else { return nil }
            return children.sorted(by: { $0.order < $1.order })
        }
        
        public init(uuid: UUID = UUID(), name: String, icon: FolderIcon, children: [Folder] = [], files: [File] = [], protected: Bool = false, order: Int = 0) {
            self.uuid = uuid
            self.name = name
            self.icon = icon
            self.children = children
            self.files = files
            self.protected = protected
            self.order = order
        }
    }
}
