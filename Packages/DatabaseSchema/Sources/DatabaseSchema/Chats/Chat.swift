//
//  Chat.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

import Foundation
import SwiftData
import AnyLanguageModel

@Model
public final class Chat {
    @Attribute(.unique)
    public var uuid: UUID
    public var createdAt: Date
    public var lastMessage: Date?
    public var transcript: Transcript = Transcript()
        
    public init(uuid: UUID = UUID(), createdAt: Date = .now) {
        self.uuid = uuid
        self.createdAt = createdAt
        self.lastMessage = nil
    }
    
    public func apply(_ transcript: Transcript) {
        self.transcript = transcript
        self.lastMessage = .now
//        self.lastMessagePreview = transcript.last.flatMap(\.plainTextPreview)
    }
}
