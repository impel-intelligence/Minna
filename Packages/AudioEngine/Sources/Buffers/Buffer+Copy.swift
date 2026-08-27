//
//  Buffer+Copy.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/27/26.
//

import AVFoundation

extension AVAudioPCMBuffer {
    func deepCopy() -> AVAudioPCMBuffer? {
        let length: AVAudioFrameCount = frameLength
        let channelCount = Int(format.channelCount)
        
        guard let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            return nil
        }
        
        for i in 0..<Int(length) {
            for channel in 0..<channelCount {
                newBuffer.floatChannelData?[channel][i] = floatChannelData?[channel][i] ?? 0.0
            }
        }
        
        newBuffer.frameLength = length
        return newBuffer
    }
}
