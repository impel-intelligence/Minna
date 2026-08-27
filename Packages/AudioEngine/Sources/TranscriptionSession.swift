//
//  TranscriptionSession.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/27/26.
//

public actor TranscriptionSession {
    private let transcriber: Transcriber
    private let recorder: EphemeralAudioRecorder
    
    private var audioStreamTask: Task<Void, Never>?
    private var transcriptionStreamTask: Task<Void, Never>?
    
    public init() async throws {
        self.transcriber = try await Transcriber(locale: .current)
        self.recorder = EphemeralAudioRecorder()
    }
    
    public func start() async throws {
        let audioStream = try await recorder.streamAudio()
        let transcriptionStream = try await transcriber.streamTranscript()
        
        audioStreamTask = Task {
            for await audio in audioStream {
                do {
                    try await transcriber.submitAudioToTranscriber(audio)
                } catch {
                    Log.logger.error("Failed to stream audio into transcriber", error: error)
                }
            }
        }
        
        transcriptionStreamTask = Task {
            for await transcription in transcriptionStream {
                print("Received transcription \(transcription.text)")
            }
        }
    }
    
    public func stop() async throws {
        try await transcriber.finishTranscribing()
        recorder.stop()
        
        audioStreamTask?.cancel()
        audioStreamTask = nil
        
        transcriptionStreamTask?.cancel()
        transcriptionStreamTask = nil
    }
}
