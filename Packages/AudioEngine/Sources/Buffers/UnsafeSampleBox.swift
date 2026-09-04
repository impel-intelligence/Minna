//
//  UnsafeSampleBox.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/4/26.
//

import ScreenCaptureKit

/// A somewhat unsafe storage for a ``CMSampleBuffer``. We copy the data passed into the `init` so the data in `buffer` is not have any references out of this box. Because of that this should be safe for Sendable.
struct UnsafeSampleBox: @unchecked Sendable {
    let buffer: CMSampleBuffer

    init(buffer: CMSampleBuffer) throws {
        try self.buffer = CMSampleBuffer(copying: buffer)
    }
}
