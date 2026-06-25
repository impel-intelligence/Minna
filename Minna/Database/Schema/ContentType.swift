//
//  ContentType.swift
//  Minna
//
//  Created by Taylor Lineman on 6/18/26.
//

import ViewStorage
import UniformTypeIdentifiers
import SFSafeSymbols

enum ContentType: Int, RawRepresentable, CustomStringConvertible, Codable, CaseIterable {
    case askMinna
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
            return .textAlignleft
        case .video:
            return .video
        case .image:
            return .photo
        case .pdf:
            return .richtextPage
        case .recording:
            return .microphone
        case .audio:
            return .waveform
        case .askMinna:
            return .sparkles
        case .text:
            return .document
        }
    }
    
    var description: String {
        switch self {
        case .askMinna:
            return "Ask Minna"
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
