//
//  AudioRecorder.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/26/26.
//

import Foundation
import Speech
import AVFoundation

/// @unchecked Sendable is safe-ish here: audioEngine is the only piece of this that is not sendable. We only access Ephemeral Audio Recorder from the actor ``TranscriptionSession``.
/// This was dreamed up by Claude but it seems to be fairly sound.
final class EphemeralAudioRecorder: @unchecked Sendable {
    enum AudioRecorderError: Error {
        case noMicrophonePermissions
    }
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    
    init() { }
    
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
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
#endif
    
    func streamAudio() async throws -> AsyncStream<UnsafeBufferBox> {
        guard await isAuthorized() else {
            throw AudioRecorderError.noMicrophonePermissions
        }
        
        try setupAudioEngine()

        let (stream, continuation) = AsyncStream.makeStream(of: UnsafeBufferBox.self, bufferingPolicy: .unbounded)

        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: audioEngine.inputNode.outputFormat(forBus: 0)) { [continuation] buffer, time in
            guard let bufferCopy = buffer.deepCopy() else {
                Log.logger.error("Failed to copy buffer")
                return
            }

            continuation.yield(UnsafeBufferBox(buffer: bufferCopy))
        }

        audioEngine.prepare()
        try audioEngine.start()

        return stream
    }
    
    private func setupAudioEngine() throws {
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}

extension EphemeralAudioRecorder {
    func isAuthorized() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }
        
        return await AVCaptureDevice.requestAccess(for: .audio)
    }
}
