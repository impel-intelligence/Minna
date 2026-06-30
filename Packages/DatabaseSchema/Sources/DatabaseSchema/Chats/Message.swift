//
//  Message.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

import Foundation
import SwiftData

@Model
public final class Message {
    @Attribute(.unique)
    public var uuid: UUID
    public var createdAt: Date
    
    public var textContent: String
    
    @Relationship(deleteRule: .nullify, inverse: \Chat.messages)
    public var chat: Chat

    public init(uuid: UUID = UUID(), createdAt: Date = .now, chat: Chat, textContent: String) {
        self.uuid = uuid
        self.createdAt = createdAt
        self.textContent = textContent
        self.chat = chat
    }
}
