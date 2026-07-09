//
//  AddFolderRequest.swift
//  Minna
//
//  Created by Taylor Lineman on 6/22/26.
//

import Foundation
import DatabaseSchema

/// Wraps the (optional) parent folder so it can drive `.sheet(item:)`. Using two
struct AddFolderRequest: Identifiable {
    let id = UUID()
    let parent: Folder?
}
