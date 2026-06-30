//
//  Chat.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

import Foundation
import SwiftData

@Model
public final class Chat {
    @Attribute(.unique)
    public var uuid: UUID
    public var createdAt: Date
    public var lastMessage: Date?
    
    @Relationship(deleteRule: .cascade) public var messages: [Message]
        
    public init(uuid: UUID = UUID(), createdAt: Date = .now) {
        self.uuid = uuid
        self.createdAt = createdAt
        self.lastMessage = nil
        self.messages = []
    }
}
