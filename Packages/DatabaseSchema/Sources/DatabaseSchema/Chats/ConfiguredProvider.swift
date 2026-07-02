//
//  ConfiguredProvider.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 7/1/26.
//

import Foundation
import SwiftData
import KeychainSwift

@Model
public final class ConfiguredProvider: Identifiable {
    @Attribute(.unique)
    public var id: UUID
    public var providerID: String
    
    @Attribute(.unique)
    public var name: String
    
    public var savedKeys: Set<String> = []
        
    public init(id: UUID = UUID(), name: String, providerID: String) {
        self.id = id
        self.providerID = providerID
        self.name = name
    }
    
    public func removeConfigurationValues() {
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        
        for key in savedKeys {
            keychain.delete(key)
        }
    }
    
    public func getConfigurationValue(for key: String) -> String? {
        let uniqueKey = "\(id.uuidString).\(providerID).\(name).\(key)"
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        return keychain.get(uniqueKey)
    }
    
    public func saveConfigurationValue(for key: String, with value: String) {
        let uniqueKey = "\(id.uuidString).\(providerID).\(name).\(key)"
        savedKeys.insert(uniqueKey)
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        keychain.set(value, forKey: uniqueKey)
    }
}

