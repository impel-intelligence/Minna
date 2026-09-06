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
    private let transcriber: Transcriber
//    private let microphoneRecorder: EphemeralMicrophoneAudioRecorder
    private let systemRecorder: EphemeralScreenCaptureKitAudioRecorder

//    private var microphoneStreamTask: Task<Void, Never>?
    private var systemStreamTask: Task<Void, Never>?
    private var transcriptionStreamTask: Task<Void, Never>?

    // Debug capture: writes the raw ScreenCaptureKit samples to a WAV so the audio fed to the transcriber can be listened to.
    private var debugAssetWriter: AVAssetWriter?
    private var debugWriterInput: AVAssetWriterInput?

    private let outputs: [any TranscriptionOutput]
        
    public init(outputs: [any TranscriptionOutput]) async throws {
        self.outputs = outputs
        self.transcriber = try await Transcriber(locale: .current)
//        self.microphoneRecorder = EphemeralMicrophoneAudioRecorder()
        self.systemRecorder = EphemeralScreenCaptureKitAudioRecorder()
    }
    
    public func start() async throws {
//        let microphoneStream = try await microphoneRecorder.streamAudio()
        let systemStream = try await systemRecorder.streamAudio()
        let transcriptionStream = try await transcriber.streamTranscript()

        setupDebugRecording()

        systemStreamTask = Task {
            do {
                for try await audio in systemStream {
                    appendDebugSample(audio)
                    try await transcriber.submitAudioToTranscriber(audio)
                }
            } catch {
                Log.logger.error("Failed to stream system audio...", error: error)
            }
        }
        
//        microphoneStreamTask = Task {
//            for await audio in microphoneStream {
//                do {
//                    try await transcriber.submitAudioToTranscriber(audio)
//                } catch {
//                    Log.logger.error("Failed to stream audio into transcriber", error: error)
//                }
//            }
//        }
        
        transcriptionStreamTask = Task {
            for await transcription in transcriptionStream {
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
        try await transcriber.finishTranscribing()
        try await systemRecorder.stop()
        await finishDebugRecording()

//        await microphoneRecorder.stop()
//        
//        microphoneStreamTask?.cancel()
//        microphoneStreamTask = nil
        
        systemStreamTask?.cancel()
        systemStreamTask = nil
        
        transcriptionStreamTask?.cancel()
        transcriptionStreamTask = nil
    }
}

// MARK: - Debug audio recording
// Authored by: Claude Fable 5 (Anthropic), based on Taylor Lineman's initial version in ScreenCaptureKitRecorder
extension TranscriptionSession {
    private func setupDebugRecording() {
        do {
            let output = FileManager.default.temporaryDirectory.appendingPathComponent("systemAudio-\(Int(Date().timeIntervalSince1970))", conformingTo: .wav)
            Log.logger.info("Debug system audio recording: \(output.path)")

            let writer = try AVAssetWriter(url: output, fileType: .wav)
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: EphemeralScreenCaptureKitAudioRecorder.SAMPLE_RATE,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ])
            input.expectsMediaDataInRealTime = true
            writer.add(input)

            debugAssetWriter = writer
            debugWriterInput = input
        } catch {
            Log.logger.error("Failed to create debug asset writer", error: error)
        }
    }

    private func appendDebugSample(_ sample: UnsafeSampleBox) {
        // Only record the system audio output. Microphone samples run on their own timeline and format, and mixing the two into one AVAssetWriterInput fails with non-monotonic timestamps.
        guard sample.type == .audio else { return }
        guard let writer = debugAssetWriter, let input = debugWriterInput else { return }

        if writer.status == .unknown {
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample.buffer))
        }

        guard writer.status == .writing, input.isReadyForMoreMediaData else { return }

        if !input.append(sample.buffer) {
            Log.logger.error("Failed to append debug sample", error: writer.error ?? TranscriptionError.invalidAudioDataType)
        }
    }

    private func finishDebugRecording() async {
        defer {
            debugAssetWriter = nil
            debugWriterInput = nil
        }

        guard let writer = debugAssetWriter, writer.status == .writing else { return }

        debugWriterInput?.markAsFinished()
        await writer.finishWriting()

        if let error = writer.error {
            Log.logger.error("Debug recording failed to finish", error: error)
        } else {
            Log.logger.info("Debug recording finished: \(writer.outputURL.path)")
        }
    }
}
