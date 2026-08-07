//
//  Chat.swift
//  DatabaseSchema
//
//  Created by Taylor Lineman on 8/7/26.
//

import Foundation
import SwiftData
import AnyLanguageModel

extension SchemaV2 {
    @Model
    public final class Chat {
        public static let defaultTitle: String = "New Chat"
        
        @Attribute(.unique)
        public var uuid: UUID
        public var createdAt: Date
        public var lastMessage: Date?
        public var transcript: Transcript = Transcript()
        
        public var theme: ThemeColor
        
        @Relationship(deleteRule: .nullify, inverse: \File.chat)
        public var file: File
        
        public var lastUsedModel: String? = nil
        
        public init(uuid: UUID = UUID(), createdAt: Date = .now, file: File) {
            self.uuid = uuid
            self.createdAt = createdAt
            self.lastMessage = nil
            self.theme = file.color
            self.file = file
        }
        
        public func apply(_ transcript: Transcript) {
            self.transcript = transcript
            self.lastMessage = .now
            //        self.lastMessagePreview = transcript.last.flatMap(\.plainTextPreview)
        }
        
        public func setModel(modelID: String) {
            self.lastUsedModel = modelID
        }
    }
}
