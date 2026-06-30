//
//  ContentType.swift
//  Minna
//
//  Created by Taylor Lineman on 6/18/26.
//

import UniformTypeIdentifiers

public enum ContentType: Int, RawRepresentable, CustomStringConvertible, Codable, CaseIterable {
    case askMinna
    case recording

    case pdf
    case image
    case video
    case text
    case audio
    
    case webpage
    
    public var description: String {
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
    
    public init?(uniformType: UTType) {
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
