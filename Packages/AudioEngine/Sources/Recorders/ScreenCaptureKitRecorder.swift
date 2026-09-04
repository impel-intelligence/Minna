//
//  SystemAudioRecorder.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/4/26.
//

import Foundation
import ScreenCaptureKit

final class SCStreamHandler: NSObject, SCStreamDelegate, SCStreamOutput {
    enum StreamHandlerError: Error {
        case userForcedStop
        case unknownError(error: Error)
    }

    let continuation: AsyncThrowingStream<UnsafeSampleBox, any Error>.Continuation
    var hasStopped: Bool = false

    init(continuation: AsyncThrowingStream<UnsafeSampleBox, any Error>.Continuation) {
        self.continuation = continuation
    }

    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard sampleBuffer.isValid else { return }
        do {
            switch type {
            case .audio:
                let sample = try UnsafeSampleBox(buffer: sampleBuffer)
                continuation.yield(sample)
            default:
                break
            }
        } catch {
            Log.logger.error("Failed to wrap buffer", error: error)
        }
    }

    public func stream(_ stream: SCStream, didStopWithError error: any Error) {
        guard !hasStopped else { return }
        hasStopped = true

        if let error = error as? SCStreamError {
            if error.code == .userStopped {
                continuation.finish(throwing: StreamHandlerError.userForcedStop)
                return
            }
        }

        continuation.finish(throwing: StreamHandlerError.unknownError(error: error))
    }
}

final actor EphemeralScreenCaptureKitAudioRecorder {
    enum SystemAudioRecorderError: Error {
        case noScreenRecordingPermissions
    }

    static let SAMPLE_RATE: Float64 = 48000

    var stream: SCStream?
    var filter: SCContentFilter?
    var streamConfig = SCStreamConfiguration()

    var streamHandler: SCStreamHandler?

    let recordingEngineQueue: DispatchQueue = .init(label: "recording_engine_queue")

    
    func stop() async throws {
        try await stream?.stopCapture()
    }
    
    func streamAudio() async throws -> AsyncThrowingStream<UnsafeSampleBox, any Error> {
        guard await isAuthorized() else {
            throw SystemAudioRecorderError.noScreenRecordingPermissions
        }

        let (stream, continuation) = AsyncThrowingStream.makeStream(of: UnsafeSampleBox.self, throwing: (any Error).self, bufferingPolicy: .unbounded)

        let handler = SCStreamHandler(continuation: continuation)
        self.streamHandler = handler
        try await setupInput(handler: handler)
    
        try await self.stream?.startCapture()

        return stream
    }

    private func setupInput(handler: SCStreamHandler) async throws {
        let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        streamConfig = SCStreamConfiguration()
        streamConfig.capturesAudio = true
        streamConfig.captureMicrophone = true
        streamConfig.channelCount = 2
        streamConfig.sampleRate = Int(Self.SAMPLE_RATE)

        guard let display = availableContent.displays.first else { return }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        self.filter = filter

        stream = SCStream(filter: filter, configuration: streamConfig, delegate: streamHandler)

        try stream?.addStreamOutput(handler, type: .screen, sampleHandlerQueue: recordingEngineQueue)
        try stream?.addStreamOutput(handler, type: .audio, sampleHandlerQueue: recordingEngineQueue)
    }

}

extension EphemeralScreenCaptureKitAudioRecorder {
    func isAuthorized() async -> Bool {
        do {
            try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }
}
