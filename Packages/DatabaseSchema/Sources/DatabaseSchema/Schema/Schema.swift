//
//  Schema.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftData

public typealias FolderIcon         = SchemaV3.FolderIcon
public typealias Folder             = SchemaV3.Folder
public typealias File               = SchemaV3.File
public typealias ConfiguredProvider = SchemaV3.ConfiguredProvider
public typealias Chat               = SchemaV3.Chat

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
    public static let schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    public static let stages: [MigrationStage] = [v1ToV2, v2ToV3]
    
    static let v1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { _ in },
        didMigrate: { context in
            let providers = try context.fetch(FetchDescriptor<SchemaV2.ConfiguredProvider>())
            for provider in providers {
                provider.cachedModelIDs = []
            }
            try context.save()
        }
    )
    
    static let v2ToV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)

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

public enum SchemaV3: VersionedSchema {
    public static let versionIdentifier: Schema.Version = Schema.Version(1, 2, 0)
    
    public static let models: [any PersistentModel.Type] = [
        // Files
        SchemaV3.File.self,
        SchemaV3.Folder.self,
        SchemaV3.FolderIcon.self,
        
        // Chats
        SchemaV3.Chat.self,
        SchemaV3.ConfiguredProvider.self
    ]
}
