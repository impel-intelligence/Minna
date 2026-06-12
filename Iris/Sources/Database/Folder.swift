//
//  Folder.swift
//  Iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import Foundation
import SwiftData
import SwiftUI

struct FolderIcon: Codable {
    enum Symbol: Codable {
        case symbol(String) // TODO: Switch to SFSymbol once that supports codable
        case emoji(String)
    }
    
    let symbol: Symbol
//    let emptySymbol: Symbol? = nil
//    let color: String
}

@Model
final class Folder: Identifiable, Hashable {
    @Attribute(.unique) 
    var uuid: UUID
    var name: String
    var icon: FolderIcon
    var protected: Bool = false
    
    @Relationship(deleteRule: .nullify) var children: [Folder]?
    @Relationship(deleteRule: .nullify, inverse: \Folder.children) var parent: Folder?

    /// SwiftData materializes an optional to-many relationship as an empty array `[]`
    /// rather than `nil` once the object is realized by the context. `OutlineGroup`
    /// treats a non-nil (but empty) children array as a collapsible branch, which draws
    /// a disclosure indicator on leaf folders. Expose `nil` for the empty case so leaves
    /// render without one.
    ///
    /// Attribution: Claude Opus 4.8
    var displayChildren: [Folder]? {
        guard let children, !children.isEmpty else { return nil }
        return children
    }

    init(uuid: UUID = UUID(), name: String, icon: FolderIcon, children: [Folder]? = nil, protected: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.icon = icon
        self.children = children
        self.protected = protected
    }
}
