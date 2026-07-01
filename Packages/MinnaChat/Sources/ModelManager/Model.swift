//
//  MinnaModel.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//

public struct Model: Hashable, Identifiable {
    public let id: String
    public let displayName: String
    public let provider: any ModelProvider.Type
    
    public var hashValue: Int {
        return id.hashValue + displayName.hashValue + provider.id.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(provider.id)
    }
    
    public static func == (lhs: Model, rhs: Model) -> Bool {
        return lhs.id == rhs.id && rhs.displayName == rhs.displayName && lhs.provider.id == rhs.provider.id
    }
}
