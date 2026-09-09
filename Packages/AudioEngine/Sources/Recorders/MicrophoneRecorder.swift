//
//  AudioRecorder.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/26/26.
//

import Foundation
import Speech
import AVFoundation

/// @unchecked Sendable is safe-ish here: audioEngine is the only piece of this that is not sendable. We only access Ephemeral Audio Recorder from the actor ``TranscriptionSession``. - This was dreamed up by Claude but it seems to be fairly sound.
final actor EphemeralAVAudioEngineMicrophoneRecorder {
    enum AudioRecorderError: Error {
        case noMicrophonePermissions
    }

    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private var device: AudioObjectID

    init(device: AudioObjectID) {
        self.device = device
    }
    
    func stop() {
        audioEngine.stop()
    }

    func pause() {
        audioEngine.pause()
    }

    func resume() throws {
        try audioEngine.start()
    }

#if os(iOS)
    func setUpAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.voiceChat, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
#endif

    func streamAudio() async throws -> AsyncStream<UnsafeBufferBox> {
        guard await isAuthorized() else {
            throw AudioRecorderError.noMicrophonePermissions
        }

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
        if let audioUnit = audioEngine.inputNode.audioUnit {
            let status = AudioUnitSetProperty(
                audioUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &device,
                UInt32(MemoryLayout<AudioDeviceID>.size)
            )
            
            try status.validateCoreAudioError()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Enable Apple's Acoustic Echo Cancellation on the microphone so we can ignore loopback from speakers playing into the mic.
        // Drops the volume of speakers sadly, so this needs to be evaluated for usefulness.
//        try audioEngine.inputNode.setVoiceProcessingEnabled(true)
//        audioEngine.inputNode.voiceProcessingOtherAudioDuckingConfiguration = AVAudioVoiceProcessingOtherAudioDuckingConfiguration(
//            enableAdvancedDucking: false,
//            duckingLevel: .min
//        )
    }
}

extension EphemeralAVAudioEngineMicrophoneRecorder {
    func isAuthorized() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }

        return await AVCaptureDevice.requestAccess(for: .audio)
    }
}
