//
//  TranscriptionSession.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/27/26.
//

public actor TranscriptionSession {
    private let transcriber: Transcriber
    private let microphoneRecorder: EphemeralMicrophoneAudioRecorder
    private let systemRecorder: EphemeralSystemAudioRecorder
    
    private var microphoneStreamTask: Task<Void, Never>?
    private var systemStreamTask: Task<Void, Never>?
    private var transcriptionStreamTask: Task<Void, Never>?
    
    private let outputs: [any TranscriptionOutput]
        
    public init(outputs: [any TranscriptionOutput]) async throws {
        self.outputs = outputs
        self.transcriber = try await Transcriber(locale: .current)
        self.microphoneRecorder = EphemeralMicrophoneAudioRecorder()
        self.systemRecorder = EphemeralSystemAudioRecorder()
    }
    
    public func start() async throws {
        let microphoneStream = try await microphoneRecorder.streamAudio()
        let systemStream = try await systemRecorder.streamAudio()
        let transcriptionStream = try await transcriber.streamTranscript()
        
        systemStreamTask = Task {
            do {
                for try await audio in systemStream {
                    try await transcriber.submitAudioToTranscriber(audio)
                }
            } catch {
                Log.logger.error("Failed to stream system audio...", error: error)
            }
        }
        
        microphoneStreamTask = Task {
            for await audio in microphoneStream {
                do {
                    try await transcriber.submitAudioToTranscriber(audio)
                } catch {
                    Log.logger.error("Failed to stream audio into transcriber", error: error)
                }
            }
        }
        
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
        await microphoneRecorder.stop()
        
        microphoneStreamTask?.cancel()
        microphoneStreamTask = nil
        
        transcriptionStreamTask?.cancel()
        transcriptionStreamTask = nil
    }
}
