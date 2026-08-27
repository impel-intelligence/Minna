//
//  UnsafeBufferBox.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/27/26.
//

import AVFAudio

/// An unsafe way to store an AVAudioPCMBuffer that can move across thread boundaries. We absolutely can not mutate the buffer in this box but there is no compiler time checks for that.
struct UnsafeBufferBox: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
}
