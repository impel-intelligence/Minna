//
//  Transcriber.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/26/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-27

import Foundation
import Speech
import AVFoundation

enum TranscriptionError: Error {
    case failedToSetupRecognitionStream
    case localeNotSupported
    case invalidAudioDataType
}

actor Transcriber {
    private let locale: Locale
    
    private let transcriber: SpeechTranscriber
    private let analyzer: SpeechAnalyzer
    private let analyzerFormat: AVAudioFormat
    
    private let inputSequence: AsyncStream<AnalyzerInput>
    private let inputBuilder: AsyncStream<AnalyzerInput>.Continuation

    private var speechRecognitionTask: Task<Void, Error>?
    
    public var downloadProgress: Progress?
    
    init(locale: Locale) async throws {
        guard await Transcriber.supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }

        self.locale = locale
        self.transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )
        self.analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw TranscriptionError.invalidAudioDataType
        }
        
        self.analyzerFormat = analyzerFormat
        (inputSequence, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
    }
    
    func streamTranscript() async throws -> AsyncStream<TranscriptionResult> {
        try await analyzer.start(inputSequence: inputSequence)

        return AsyncStream(TranscriptionResult.self, bufferingPolicy: .unbounded) { continuation in
            speechRecognitionTask = Task {
                do {
                    for try await result in transcriber.results {
                        let transcriptionResult = TranscriptionResult(text: result.text, range: result.range, isFinal: result.isFinal)
                        continuation.yield(transcriptionResult)
                    }
                } catch is CancellationError {
                    Log.logger.warning("Speech recognition task cancelled")
                } catch {
                    Log.logger.error("Failed to run speech analyzer", error: error)
                }
            
                continuation.finish()
            }
        }
    }
    
    func submitAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        let converted = try BufferConverter.standardizeBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)
        
        inputBuilder.yield(input)
    }
    
    public func finishTranscribing() async throws {
        inputBuilder.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        speechRecognitionTask?.cancel()
        speechRecognitionTask = nil
        await releaseLocales()
    }
}

extension Transcriber {
    public func ensureModel() async throws {
        if await Transcriber.installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }
    
    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            self.downloadProgress = downloader.progress
            try await downloader.downloadAndInstall()
        }
    }
    
    func releaseLocales() async {
        let reserved = await AssetInventory.reservedLocales
        for locale in reserved {
            await AssetInventory.release(reservedLocale: locale)
        }
    }
    
    static func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    static func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }
}
