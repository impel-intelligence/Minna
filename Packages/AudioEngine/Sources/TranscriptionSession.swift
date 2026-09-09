//
//  TranscriptionSession.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/27/26.
//  Edited by Claude Fable 5 (Anthropic) on 2026-09-04
//

import AVFoundation
import Foundation
import ScreenCaptureKit

// TODO: Need to de-dedup and re-order the output transcription so it aligns with the time codes of each stream.
public actor TranscriptionSession {
    enum TranscriptionSessionError: Error {
        case unableToGetDevice
        case microphoneNotInitialized
    }
    
    private var microphoneTranscriber: Transcriber?
    private var microphoneRecorder: EphemeralAVAudioEngineMicrophoneRecorder?
    
    private var systemTranscriber: Transcriber?
    private var systemRecorder: EphemeralCoreAudioSystemRecorder?

    private var microphoneStreamTask: Task<Void, Never>?
    private var systemStreamTask: Task<Void, Never>?
    
    private var systemTranscriptionStreamTask: Task<Void, Never>?
    private var microphoneTranscriptionStreamTask: Task<Void, Never>?

    // Debug capture: writes the raw ScreenCaptureKit samples to a WAV so the audio fed to the transcriber can be listened to.
    private var debugAssetWriter: AVAssetWriter?
    private var debugWriterInput: AVAssetWriterInput?

    private let outputs: [any TranscriptionOutput]
        
    public init(outputs: [any TranscriptionOutput]) async throws {
        self.outputs = outputs
    }
    
    public func attachMicrophoneTranscriber(device: AudioObjectID) async throws {
        self.microphoneTranscriber = try await Transcriber(locale: .current)
        self.microphoneRecorder = EphemeralAVAudioEngineMicrophoneRecorder(device: device)
    }
    
    public func detachMicrophoneTranscriber() async throws {
        try await stopMicrophoneTranscription()
        
        self.microphoneTranscriber = nil
        self.microphoneRecorder = nil
    }
    
    public func startMicrophoneTranscription() async throws {
        // Assigned together so there should never be one without the other.
        guard let microphoneRecorder, let microphoneTranscriber else {
            throw TranscriptionSessionError.microphoneNotInitialized
        }
        
        let microphoneStream = try await microphoneRecorder.streamAudio()

        microphoneStreamTask = Task {
            for await audio in microphoneStream {
                do {
                    try await microphoneTranscriber.submitAudioToTranscriber(audio)
                } catch {
                    Log.logger.error("Failed to stream microphone", error: error)
                }
            }
        }

        let microphoneTranscriptionStream = try await microphoneTranscriber.streamTranscript()

        microphoneTranscriptionStreamTask = Task {
            for await transcription in microphoneTranscriptionStream {
                for output in outputs {
                    if transcription.isFinal {
                        await output.submitFinalized(string: transcription.text)
                    } else {
                        await output.submitVolatile(string: transcription.text)
                    }
                }
            }
        }
    }
    
    public func stopMicrophoneTranscription() async throws {
        defer {
            microphoneStreamTask?.cancel()
            microphoneStreamTask = nil
            
            microphoneTranscriptionStreamTask?.cancel()
            microphoneTranscriptionStreamTask = nil
        }
        
        // Assigned together so there should never be one without the other.
        guard let microphoneRecorder, let microphoneTranscriber else {
            throw TranscriptionSessionError.microphoneNotInitialized
        }

        await microphoneRecorder.stop()
        try await microphoneTranscriber.finishTranscribing()
    }

    
    public func attachSystemTranscriber() async throws {
        self.systemTranscriber = try await Transcriber(locale: .current)
        self.systemRecorder = EphemeralCoreAudioSystemRecorder()
    }
    
    public func detachSystemTranscriber() async throws {
        try await stopSystemTranscription()
        
        self.systemTranscriber = nil
        self.systemRecorder = nil
    }
    
    public func startSystemTranscription() async throws {
        // Assigned together so there should never be one without the other.
        guard let systemRecorder, let systemTranscriber else {
            throw TranscriptionSessionError.microphoneNotInitialized
        }

        let systemStream = try await systemRecorder.streamAudio()
        
        systemStreamTask = Task {
            do {
                for try await audio in systemStream {
                    try await systemTranscriber.submitAudioToTranscriber(audio)
                }
            } catch {
                Log.logger.error("Failed to stream system audio", error: error)
            }
        }
        
        let systemTranscriptionStream = try await systemTranscriber.streamTranscript()

        systemTranscriptionStreamTask = Task {
            for await transcription in systemTranscriptionStream {
                for output in outputs {
                    if transcription.isFinal {
                        await output.submitFinalized(string: transcription.text)
                    } else {
                        await output.submitVolatile(string: transcription.text)
                    }
                }
            }
        }
    }
    
    public func stopSystemTranscription() async throws {
        defer {
            systemStreamTask?.cancel()
            systemStreamTask = nil
            
            systemTranscriptionStreamTask?.cancel()
            systemTranscriptionStreamTask = nil
        }

        // Assigned together so there should never be one without the other.
        guard let systemRecorder, let systemTranscriber else {
            throw TranscriptionSessionError.microphoneNotInitialized
        }

        await systemRecorder.stop()
        try await systemTranscriber.finishTranscribing()
    }
}
