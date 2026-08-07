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
