//
//  Schema.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftData

public extension Schema {
    static let minnaSchema: Schema = Schema([
        // Files
        File.self,
        Folder.self,
        FolderIcon.self,
        
        // Chats
        Chat.self,
        ChatModel.self,
        ConfiguredProvider.self
    ])
}
