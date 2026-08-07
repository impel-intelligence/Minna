//
//  ConfiguredProvider.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 8/7/26.
//

import Foundation
import SwiftData
import KeychainSwift

extension SchemaV2 {
    @Model
    public final class ConfiguredProvider: Identifiable {
        @Attribute(.unique)
        public var id: UUID
        public var providerID: String
        
        @Attribute(.unique)
        public var name: String
        
        public var savedKeys: Set<String> = []
        public var cachedModelIDs: Set<String> = []
        
        public init(id: UUID = UUID(), name: String, providerID: String) {
            self.id = id
            self.providerID = providerID
            self.name = name
        }
    }
}

