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
    
    public var file: File

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
}

extension Chat {
    public static func create(in folder: Folder, context: ModelContext) -> Chat {
        let id = UUID()
        let file = File(
            uuid: id, createdAt: .now, folder: folder,title: defaultTitle,
            shortDescription: "", color: .random, type: .askMinna,
            url: URL(string: "iris-chat://\(id)")!, bookmark: nil,
            source: "Ask Minna"
        )
        let chat = Chat(uuid: id, createdAt: .now, file: file)
        file.chat = chat
        file.searchIndexed = true
        file.descriptionGenerated = true
        context.insert(file)
        return chat
    }
}
