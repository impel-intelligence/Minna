//
//  Chat.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/30/26.
//

import Foundation
import SwiftData
import AnyLanguageModel

extension Chat {
    /// Builds a chat and its backing ``File`` entirely in memory, without inserting
    /// into a `ModelContext`. Insertion is the caller's responsibility and should
    /// happen only once the chat has real content (e.g. the first message), so an
    /// abandoned compose does not leave an empty chat behind.
    ///
    /// The ``File`` and ``Chat`` share one `UUID` so the synthesized `minna://doc/`
    /// URL deterministically identifies the chat. `searchIndexed` /
    /// `descriptionGenerated` are pre-marked so the background indexing sweep never
    /// tries to fetch content for an `minna-chat://` URL.
    ///
    /// - Parameter folder: The (already persisted) folder the chat's file belongs to.
    /// - Returns: An un-inserted ``Chat``; call `context.insert(chat.file)` to persist.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    public static func make(in folder: Folder) -> Chat {
        let id = UUID()
        let file = File(
            uuid: id, createdAt: .now, folder: folder, title: defaultTitle,
            shortDescription: "", color: .random, type: .askMinna,
            url: URL(string: "minna://doc/\(id)")!, bookmark: nil,
            source: "Ask Minna"
        )
        let chat = Chat(uuid: id, createdAt: .now, file: file)
        file.chat = chat
        file.searchIndexed = true
        file.descriptionGenerated = true
        return chat
    }
    
    /// Attaches a ``Chat`` instance to the given `file`.
    ///
    /// The chat is not persisted in the database until `context.insert(chat)` is called
    /// - Parameter file: The file to attach the new chat to
    /// - Returns: An un-inserted ``Chat``; call `context.insert(chat)` to persist.
    public static func make(on file: File) -> Chat {
        let chat = Chat(uuid: file.uuid, createdAt: .now, file: file)
        file.chat = chat
        
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
