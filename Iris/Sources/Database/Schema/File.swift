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
import ViewStorage
import UniformTypeIdentifiers

enum ContentType: Int, RawRepresentable, CustomStringConvertible, Codable, CaseIterable {
    case askIris
    case recording

    case pdf
    case image
    case video
    case text
    case audio
    
    case webpage
    
    var icon: SFSymbol {
        switch self {
        case .webpage:
            return .text_alignleft
        case .video:
            return .video
        case .image:
            return .photo
        case .pdf:
            return .doc_richtext
        case .recording:
            return .mic
        case .audio:
            return .waveform
        case .askIris:
            return .sparkles
        case .text:
            return .doc
        }
    }
    
    var description: String {
        switch self {
        case .askIris:
            return "Ask Iris"
        case .recording:
            return "Recording"
        case .pdf:
            return "PDF"
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .text:
            return "Text File"
        case .webpage:
            return "Webpage"
        case .audio:
            return "Audio"
        }
    }
    
    init?(uniformType: UTType) {
        switch uniformType {
        case let type where type.conforms(to: .image):
            self = .image
        case let type where type.conforms(to: .audio):
            self = .audio
        case let type where type.conforms(to: .video):
            self = .video
        case let type where type.conforms(to: .text):
            self = .text
        case let type where type.conforms(to: .pdf):
            self = .pdf
        default:
            return nil
        }
    }
}

extension ContentType: ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> ContentType? {
        (store.object(forKey: key) as? Int).flatMap({ ContentType(rawValue: $0) })
    }

    public func write(to store: UserDefaults, forKey key: String) {
        store.set(rawValue, forKey: key)
    }
}

@Model
final class File {
    @Attribute(.unique) 
    var uuid: UUID
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Folder.files)
    var folder: Folder
    
    var title: String
    var shortDescription: String
    var color: ThemeColor
    @Attribute(.unique) var url: URL
    var bookmark: Data?
    var type: ContentType = ContentType.webpage
    var source: String
//    var order: Int

    init(uuid: UUID = UUID(), createdAt: Date, folder: Folder, title: String, shortDescription: String, color: ThemeColor, type: ContentType, url: URL, bookmark: Data?, source: String/*, order: Int*/) {
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
//        self.order = order
    }
}
