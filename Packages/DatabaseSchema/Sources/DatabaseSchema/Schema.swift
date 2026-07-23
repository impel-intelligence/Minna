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
        ConfiguredProvider.self
    ])
}

public enum DatabaseMigrationPlan: SchemaMigrationPlan {
    public static let schemas: [any VersionedSchema.Type] = [SchemaV1.self]
    public static let stages: [MigrationStage] = []
}

public enum SchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    
    public static let models: [any PersistentModel.Type] = [
        // Files
        File.self,
        Folder.self,
        FolderIcon.self,
        
        // Chats
        Chat.self,
        ConfiguredProvider.self
    ]
}
