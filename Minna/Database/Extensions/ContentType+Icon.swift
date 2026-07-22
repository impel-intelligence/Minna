//
//  ContentType+Icon.swift
//  Minna
//
//  Created by Taylor Lineman on 6/30/26.
//

import DatabaseSchema
import ViewStorage
import SFSafeSymbols

extension ContentType {
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
        case .slides:
            return .rectangleStack
        }
    }
}
