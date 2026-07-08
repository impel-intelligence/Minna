//
//  Database.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

import Foundation
import DatabaseSchema

protocol Database {
    var unfilledFolderUUID: UUID { get }
    
    func queueDescriptionUpdate(for file: File)
}
