//
// Source:
// - https://developer.apple.com/videos/play/wwdc2025/277
// - https://developer.apple.com/documentation/Speech/bringing-advanced-speech-to-text-capabilities-to-your-app
//

import Foundation
import AVFoundation

class BufferConverter {
    enum Error: Swift.Error {
        case failedToCreateConverter
        case failedToCreateConversionBuffer
        case conversionFailed(NSError?)
    }
    
    static func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        guard inputFormat != format else { return buffer }
            
        guard var converter = AVAudioConverter(from: inputFormat, to: format) else { throw Error.failedToCreateConverter }
        
        // Sacrifice quality of first samples in order to avoid any timestamp drift from source
        converter.primeMethod = .none

        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))
        
        guard let conversionBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frameCapacity) else {
            throw Error.failedToCreateConversionBuffer
        }
                
        try converter.convert(to: conversionBuffer, from: buffer)
                
        return conversionBuffer
    }
}
