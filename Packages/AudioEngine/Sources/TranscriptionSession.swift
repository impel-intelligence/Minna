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

public actor TranscriptionSession {
    private let microphoneTranscriber: Transcriber
    private let microphoneRecorder: EphemeralAVAudioEngineMicrophoneRecorder
    
    private let systemTranscriber: Transcriber
    private let systemRecorder: EphemeralCoreAudioSystemRecorder

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
        self.microphoneTranscriber = try await Transcriber(locale: .current)
        self.microphoneRecorder = EphemeralAVAudioEngineMicrophoneRecorder()
        
        self.systemTranscriber = try await Transcriber(locale: .current)
        self.systemRecorder = EphemeralCoreAudioSystemRecorder()
    }
    
    public func start() async throws {
        let microphoneStream = try await microphoneRecorder.streamAudio()
        let systemStream = try await systemRecorder.streamAudio()
        
        systemStreamTask = Task {
            do {
                for try await audio in systemStream {
                    try await systemTranscriber.submitAudioToTranscriber(audio)
                }
            } catch {
                Log.logger.error("Failed to stream system audio...", error: error)
            }
        }
        
        microphoneStreamTask = Task {
            for await audio in microphoneStream {
                do {
                    try await microphoneTranscriber.submitAudioToTranscriber(audio)
                } catch {
                    Log.logger.error("Failed to stream audio into transcriber", error: error)
                }
            }
        }

        // TODO: Need to de-dedup and re-order the output transcription so it aligns with the time codes of each stream/
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
    
    public func stop() async throws {
        await systemRecorder.stop()

        await microphoneRecorder.stop()

        microphoneStreamTask?.cancel()
        microphoneStreamTask = nil
        
        systemStreamTask?.cancel()
        systemStreamTask = nil
        
        systemTranscriptionStreamTask?.cancel()
        systemTranscriptionStreamTask = nil
        
        microphoneTranscriptionStreamTask?.cancel()
        microphoneTranscriptionStreamTask = nil
        
        //        try await microphoneTranscriber.finishTranscribing()
        //        try await systemTranscriber.finishTranscribing()
    }
}
