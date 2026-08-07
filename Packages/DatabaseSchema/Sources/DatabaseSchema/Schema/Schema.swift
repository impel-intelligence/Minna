//
//  Schema.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftData

public typealias FolderIcon = SchemaV2.FolderIcon
public typealias Folder = SchemaV2.Folder
public typealias File = SchemaV2.File
public typealias ConfiguredProvider = SchemaV2.ConfiguredProvider
public typealias Chat = SchemaV2.Chat

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
    public static let schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self]
    public static let stages: [MigrationStage] = [v1ToV2]
    
    static let v1ToV2 = MigrationStage.lightweight(
      fromVersion: SchemaV1.self,
      toVersion: SchemaV2.self
    )
}

public enum SchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    
    public static let models: [any PersistentModel.Type] = [
        // Files
        SchemaV1.File.self,
        SchemaV1.Folder.self,
        SchemaV1.FolderIcon.self,
        
        // Chats
        SchemaV1.Chat.self,
        SchemaV1.ConfiguredProvider.self
    ]
}

public enum SchemaV2: VersionedSchema {
    public static let versionIdentifier: Schema.Version = Schema.Version(1, 1, 0)
    
    public static let models: [any PersistentModel.Type] = [
        // Files
        SchemaV2.File.self,
        SchemaV2.Folder.self,
        SchemaV2.FolderIcon.self,
        
        // Chats
        SchemaV2.Chat.self,
        SchemaV2.ConfiguredProvider.self
    ]
}
