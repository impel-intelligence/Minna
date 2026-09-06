//
//  UnsafeSampleBox.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/4/26.
//  Edited by Claude Fable 5 (Anthropic) on 2026-09-04
//

import ScreenCaptureKit

/// A somewhat unsafe storage for a ``CMSampleBuffer``. We copy the data passed into the `init` so the data in `buffer` is not have any references out of this box. Because of that this should be safe for Sendable.
struct UnsafeSampleBox: @unchecked Sendable {
    let buffer: CMSampleBuffer
    /// Which SCStream output produced this sample (`.audio` for system audio, `.microphone` for the mic).
    let type: SCStreamOutputType

    init(buffer: CMSampleBuffer, type: SCStreamOutputType) throws {
        try self.buffer = CMSampleBuffer(copying: buffer)
        self.type = type
    }
}
