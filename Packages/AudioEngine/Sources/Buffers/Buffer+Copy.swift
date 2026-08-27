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
        
        newBuffer.copy(from: self)
        return newBuffer
    }
}

extension AVAudioPCMBuffer {
    @discardableResult func copy(from buffer: AVAudioPCMBuffer, readOffset: AVAudioFrameCount = 0, frames: AVAudioFrameCount = 0) -> AVAudioFrameCount {
        let remainingCapacity = frameCapacity - frameLength
        if remainingCapacity == 0 {
            Log.logger.error("AVAudioBuffer copy(from) - no capacity!")
            return 0
        }

        if format != buffer.format {
            Log.logger.error("AVAudioBuffer copy(from) - formats must match!")
            return 0
        }

        let totalFrames = Int(min(min(frames == 0 ? buffer.frameLength : frames, remainingCapacity),
                                  buffer.frameLength - readOffset))

        if totalFrames <= 0 {
            Log.logger.error("AVAudioBuffer copy(from) - No frames to copy!")
            return 0
        }

        let frameSize = Int(format.streamDescription.pointee.mBytesPerFrame)
        if let src = buffer.floatChannelData,
           let dst = floatChannelData
        {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else if let src = buffer.int16ChannelData,
                  let dst = int16ChannelData
        {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else if let src = buffer.int32ChannelData,
                  let dst = int32ChannelData
        {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else {
            return 0
        }
        frameLength += AVAudioFrameCount(totalFrames)
        return AVAudioFrameCount(totalFrames)
    }
}
