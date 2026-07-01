//
//  ChatModel.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 6/30/26.
//

import Foundation
import SwiftData

public enum ModelSource: Int, Codable {
    case apple
    case huggingFace
}

public enum ModelLocation: Int, Codable {
    case device
    case cloud
}

@Model
public final class ChatModel: Identifiable {
    @Attribute(.unique)
    public var id: String
    public var source: ModelSource
    public var location: ModelLocation
   
    public init(id: String, source: ModelSource, location: ModelLocation) {
        self.id = id
        self.source = source
        self.location = location
    }
}
