//
//  Transcriber.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/26/26.
//

import Foundation
import Speech
import AVFoundation

enum TranscriptionError: Error {
    case failedToSetupRecognitionStream
    case localeNotSupported
    case invalidAudioDataType
}

class Transcriber {
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var inputSequence: AsyncStream<AnalyzerInput>?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    
    public var downloadProgress: Progress?

    // The audio format to record into.
    var analyzerFormat: AVAudioFormat?
    
    var speechRecognitionTask: Task<Void, Error>?
    
    let locale: Locale
    
    init(locale: Locale) {
        self.locale = locale
    }
    
    func setupTranscriber() async throws {
        transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )
        
        // Transcriber will always be true since SpeechTranscriber is not a nullable init.
        guard let transcriber else { throw TranscriptionError.failedToSetupRecognitionStream }
        analyzer = SpeechAnalyzer(modules: [transcriber])

        try await ensureModel(transcriber: transcriber, locale: locale)

        self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        (inputSequence, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
        
        guard let inputSequence else { return }
        
        speechRecognitionTask = Task {
            do {
                for try await case let result in transcriber.results {
                    
//                    let text = result.text
//                    if result.isFinal {
//                        finalizedTranscript += text
//                        volatileTranscript = ""
//                        updateStoryWithNewText(withFinal: text)
//                    } else {
//                        volatileTranscript = text
//                        volatileTranscript.foregroundColor = .purple.opacity(0.4)
//                    }
                }
            } catch {
                print("speech recognition failed")
            }
        }
        
        try await analyzer?.start(inputSequence: inputSequence)
    }
    
    
    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let inputBuilder, let analyzerFormat else {
            throw TranscriptionError.invalidAudioDataType
        }
        
        let converted = try BufferConverter.convertBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)
        
        inputBuilder.yield(input)
    }
//    
//    public func finishTranscribing() async throws {
//        inputBuilder?.finish()
//        try await analyzer?.finalizeAndFinishThroughEndOfInput()
//        recognizerTask?.cancel()
//        recognizerTask = nil
//    }
}

extension Transcriber {
    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }
        
        if await installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }
    
    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
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
}
