//
//  SystemAudioRecorder.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/8/26.
//
//

import Foundation
import Speech
import AVFoundation

/// @unchecked Sendable is safe-ish here: audioEngine is the only piece of this that is not sendable. We only access Ephemeral Audio Recorder from the actor ``TranscriptionSession``. - This was dreamed up by Claude but it seems to be fairly sound.
final actor EphemeralCoreAudioSystemRecorder {
    enum SystenRecorderError: Error {
        case couldNotCreateSystemTap
    }

    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private var aggregateDevice: AggregateDevice?
    private var systemTap: AudioTap?

    init() { }
    
    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        aggregateDevice = nil
        systemTap = nil
    }

    func pause() {
        audioEngine.pause()
    }

    func resume() throws {
        try audioEngine.start()
    }

    func streamAudio() async throws -> AsyncStream<UnsafeBufferBox> {
        try setupAudioEngine()

        let (stream, continuation) = AsyncStream.makeStream(of: UnsafeBufferBox.self, bufferingPolicy: .unbounded)

        let hwFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [continuation] buffer, time in
            guard let bufferCopy = buffer.deepCopy() else {
                Log.logger.error("Failed to copy buffer")
                return
            }

            continuation.yield(UnsafeBufferBox(buffer: bufferCopy, time: time))
        }

        audioEngine.prepare()
        try audioEngine.start()

        return stream
    }

    private func setupAudioEngine() throws {
        // Create a system tap
        let tapConfig = TapConfig(name: "Minna System Tap", isPrivate: true, exclusive: true, device: nil)
        systemTap = try AudioTap.new(config: tapConfig)
        guard let systemTap else { throw SystenRecorderError.couldNotCreateSystemTap }
    
        let systemTapUID = try systemTap.id.tap.uid
        
        let aggregateConfig = CompositionConfig(
            name: "Minna-Audio-Recorder",
            uid: UUID().uuidString,
            subDeviceUIDs: [],
            tapUIDs: [
                CompositionConfig.TapEntry(uid: systemTapUID, driftCompensation: true)
            ],
            isPrivate: true,
            autoStart: true,
            isStacked: false,
        )
    
        aggregateDevice = try AggregateDevice.new(config: aggregateConfig)
    
        if let aggregateDevice {
            var deviceID = aggregateDevice.id
    
            let status = AudioUnitSetProperty(
                audioEngine.inputNode.audioUnit!,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &deviceID,
                UInt32(MemoryLayout<AudioDeviceID>.size)
            )
    
            try status.validateCoreAudioError()
        }
    }
}
