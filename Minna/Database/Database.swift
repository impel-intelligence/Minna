//
//  Database.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

import Foundation
import DatabaseSchema
import SwiftData

protocol Database {
    var unfilledFolderUUID: UUID { get }
    var context: ModelContext { get }
    
    func unfilledFolder() -> Folder
    func queueDescriptionUpdate(for file: File)
}
