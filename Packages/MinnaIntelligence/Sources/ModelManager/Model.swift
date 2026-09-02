//
//  MinnaModel.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//

public protocol Model: Sendable, Hashable, Identifiable, Equatable {
    var id: String { get }
    var displayName: String { get }
    var provider: any ModelProvider.Type { get }
}

public struct SimpleModel: Model, Sendable, Hashable, Identifiable {
    public let id: String
    public let displayName: String
    public let provider: any ModelProvider.Type

    public init(id: String, displayName: String, provider: any ModelProvider.Type) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
    }

    public var hashValue: Int {
        return id.hashValue + displayName.hashValue + provider.id.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(provider.id)
    }

    public static func == (lhs: SimpleModel, rhs: SimpleModel) -> Bool {
        return lhs.id == rhs.id && rhs.displayName == rhs.displayName && lhs.provider.id == rhs.provider.id
    }
}
