//
// Source:
// - https://developer.apple.com/videos/play/wwdc2025/277
// - https://developer.apple.com/documentation/Speech/bringing-advanced-speech-to-text-capabilities-to-your-app
//

import Foundation
@preconcurrency import AVFAudio

class BufferConverter {
    enum ConversionError: Error {
        case failedToCreateConverter
        case failedToCreateConversionBuffer
        case conversionFailed(NSError?)

        case couldNotCreateStreamDescription
        case failedToCreateDescriptor
        case couldNotGetSampleRate
        case couldNotCreateBlockBuffer
        case couldNotGetDataPointer
        case failedToGetSourceFormat
    }
    
    private final class BoolBox: @unchecked Sendable {
        var value: Bool = false
        init(value: Bool) { self.value = value }
    }
    
    static func convertSample(_ sampleBox: UnsafeSampleBox, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard let description = CMSampleBufferGetFormatDescription(sampleBox.buffer) else {
            throw ConversionError.failedToCreateDescriptor
        }

        guard var audioStreamDescription = description.audioStreamBasicDescription else {
            throw ConversionError.couldNotCreateStreamDescription
        }

        guard let sourceFormat = AVAudioFormat(streamDescription: &audioStreamDescription) else {
            throw ConversionError.failedToGetSourceFormat
        }

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBox.buffer))

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw ConversionError.failedToCreateConversionBuffer
        }
        
        pcmBuffer.frameLength = frameCount
        
        try sampleBox.buffer.copyPCMData(fromRange: 0..<Int(frameCount), into: pcmBuffer.mutableAudioBufferList)

        return try standardizeBuffer(pcmBuffer, to: format)
    }


    
    static func standardizeBuffer(_ bufferBox: UnsafeBufferBox, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        return try standardizeBuffer(bufferBox.buffer, to: format)
    }

    static func standardizeBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer{
        let inputFormat = buffer.format
        guard inputFormat != format else { return buffer }
            
        guard let converter = AVAudioConverter(from: inputFormat, to: format) else {
            throw ConversionError.failedToCreateConverter
        }
        
        // Sacrifice quality of first samples in order to avoid any timestamp drift from source
        converter.primeMethod = .none

        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))
        
        guard let conversionBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frameCapacity) else {
            throw ConversionError.failedToCreateConversionBuffer
        }
                
        var nsError: NSError?
        
        // THIS IS UNSAFE!!! The only way around the 'Reference to captured var 'bufferProcessed' in concurrently-executing code' error in Swift 6.2 is to wrap the boolean into an class with an immutable reference where we mutate the class state.
        // This is kind of safe since the value is only ever altered in the one convert closure
        let bufferProcessed = BoolBox(value: false)
        
        let status = converter.convert(to: conversionBuffer, error: &nsError) { packetCount, inputStatusPointer in
            // This closure can be called multiple times, but it only offers a single buffer.
            defer { bufferProcessed.value = true }
            inputStatusPointer.pointee = bufferProcessed.value ? .noDataNow : .haveData
            return bufferProcessed.value ? nil : buffer
        }
        
        guard status != .error else {
            throw ConversionError.conversionFailed(nsError)
        }
        
        return conversionBuffer

    }
}
