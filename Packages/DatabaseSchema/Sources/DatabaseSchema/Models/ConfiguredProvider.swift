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
        
    public init(id: UUID = UUID(), providerID: String) {
        self.id = id
        self.providerID = providerID
    }
    
    public func getConfigurationValue(for key: String) -> String? {
        let uniqueKey = "\(id.uuidString).\(providerID).\(key)"

        let keychain = KeychainSwift()
        keychain.synchronizable = true
        return keychain.get(uniqueKey)
    }
    
    public func saveConfigurationValue(for key: String, with value: String) {
        let uniqueKey = "\(id.uuidString).\(providerID).\(key)"
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        keychain.set(value, forKey: uniqueKey)
    }
}

