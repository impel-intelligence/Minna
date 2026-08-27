//
//  AudioRecorder.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/26/26.
//

import Foundation
import Speech
import AVFoundation

class EphemeralAudioRecorder {
    enum AudioRecorderError: Error {
        case noMicrophonePermissions
    }
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()

    private var outputContinuation: AsyncStream<UnsafeBufferBox>.Continuation? = nil

    var playerNode: AVAudioPlayerNode?
    
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
    
    func streamAudio() throws -> AsyncStream<UnsafeBufferBox> {
        try setupAudioEngine()
        
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: audioEngine.inputNode.outputFormat(forBus: 0)) { buffer, time in
            guard let bufferCopy = buffer.deepCopy() else {
                Log.logger.error("Failed to copy buffer")
                return
            }
            let box = UnsafeBufferBox(buffer: bufferCopy)
            self.outputContinuation?.yield(box)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return AsyncStream(UnsafeBufferBox.self, bufferingPolicy: .unbounded) { continuation in
            outputContinuation = continuation
        }
    }
    
    private func setupAudioEngine() throws {
        let inputSettings = audioEngine.inputNode.inputFormat(forBus: 0).settings
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
