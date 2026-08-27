//
//  TranscriptionChunk.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/27/26.
//

import Foundation
import CoreMedia

struct TranscriptionChunk {
    public let text: AttributedString
    public let range: CMTimeRange
    public let isFinal: Bool
}
