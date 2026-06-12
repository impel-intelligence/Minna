//
//  ContentItem.swift
//  Iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import Foundation
import SwiftData
import SFSymbols
import SwiftUI

enum ThemeColor: Int, Codable {
    case apricot
    case berry
    case blueberry
    case melon
    case grape
}

enum ContentType {
    case externalURL
    case localURL
    case image
    case recording
}

@Model
final class ContentItem {
    @Attribute(.unique) 
    var uuid: UUID
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var folder: Folder
    
    var title: String
    var shortDescription: String
    var color: ThemeColor
    var url: URL
    var bookmark: Data?
    var source: String

    init(uuid: UUID, createdAt: Date, folder: Folder, title: String, shortDescription: String, color: ThemeColor, contentURL: URL, bookmark: Data?, url: URL, source: String) {
        self.uuid = uuid
        self.createdAt = createdAt
        self.folder = folder
        self.title = title
        self.shortDescription = shortDescription
        self.color = color
        self.bookmark = bookmark
        self.url = url
        self.source = source
    }
}
