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
        self.theme = .random
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

extension Chat {
    /// Builds a chat and its backing `File` entirely in memory, without inserting
    /// into a `ModelContext`. Insertion is the caller's responsibility and should
    /// happen only once the chat has real content (e.g. the first message), so an
    /// abandoned compose does not leave an empty chat behind.
    ///
    /// The `File` and `Chat` share one `UUID` so the synthesized `iris-chat://`
    /// URL deterministically identifies the chat. `searchIndexed` /
    /// `descriptionGenerated` are pre-marked so the background indexing sweep never
    /// tries to fetch content for an `iris-chat://` URL.
    ///
    /// - Parameter folder: The (already persisted) folder the chat's file belongs to.
    /// - Returns: An un-inserted `Chat`; call `context.insert(chat.file)` to persist.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public static func make(in folder: Folder) -> Chat {
        let id = UUID()
        let file = File(
            uuid: id, createdAt: .now, folder: folder, title: defaultTitle,
            shortDescription: "", color: .random, type: .askMinna,
            url: URL(string: "iris-chat://\(id)")!, bookmark: nil,
            source: "Ask Minna"
        )
        let chat = Chat(uuid: id, createdAt: .now, file: file)
        file.chat = chat
        file.searchIndexed = true
        file.descriptionGenerated = true
        return chat
    }
}

extension Chat {
    public func title() -> String {
        if !file.title.isEmpty, file.title != Chat.defaultTitle {
            return file.title
        }
        return "Ask Minna"
    }
}
