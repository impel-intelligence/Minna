//
//  Folder.swift
//  Minna
//
//  Created by Taylor Lineman on 6/11/26.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

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

extension Folder {
    public var transferRepresentation: FolderTransfer { FolderTransfer(uuid: self.uuid) }
    
    /// Search up the parent tree to see if `ancestor` is found.
    /// - Parameter ancestor: A folder that could be a parent or ancestor of this folder.
    /// - Returns: True if `self` is `ancestor` or appears anywhere in its subtree.
    public func isDescendent(of ancestor: Folder) -> Bool {
        var node: Folder? = self
        while let current = node {
            if current.uuid == ancestor.uuid { return true }
            node = current.parent
        }
        return false
    }
}

public extension UTType {
    static nonisolated let irisFolder = UTType(exportedAs: "com.irissearch.index")
}

/// SwiftData's `@Model` macro does not synthesize `Codable`, so `Folder` cannot
/// back a `CodableRepresentation` directly. This lightweight, `Codable` proxy
/// carries the folder's identity across a drag, and the drop site resolves it
/// back to a `Folder` via the model context.
///
/// Attribution: Claude Opus 4.8
public struct FolderTransfer: Codable, Transferable {
    public let uuid: UUID
    
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .irisFolder)
    }
}
