//
//  File.swift
//  Iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import Foundation
import SwiftData
import SFSymbols
import SwiftUI

enum ContentType: Int, Codable {
    case externalURL
    case localURL
    case image
    case recording
    case askIris
    
    var icon: SFSymbol {
        switch self {
        case .externalURL:
            .text_alignleft
        case .localURL:
            .text_alignleft
        case .image:
            .photo
        case .recording:
            .mic
        case .askIris:
            .sparkles
        }
    }
}

@Model
final class File {
    @Attribute(.unique) 
    var uuid: UUID
    var createdAt: Date
    
    @Relationship(deleteRule: .noAction, inverse: \Folder.files)
    var folder: Folder
    
    var title: String
    var shortDescription: String
    var color: ThemeColor
    var url: URL
    var bookmark: Data?
    var type: ContentType = ContentType.localURL
    var source: String
    var order: Int

    init(uuid: UUID = UUID(), createdAt: Date, folder: Folder, title: String, shortDescription: String, color: ThemeColor, type: ContentType, url: URL, bookmark: Data?, source: String, order: Int) {
        self.uuid = uuid
        self.createdAt = createdAt
        self.folder = folder
        self.title = title
        self.shortDescription = shortDescription
        self.color = color
        self.type = type
        self.bookmark = bookmark
        self.url = url
        self.source = source
        self.order = order
    }
}
