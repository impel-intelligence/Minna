//
//  RecordingWindow.swift
//  Minna
//
//  Created by Taylor Lineman on 8/26/26.
//

import SwiftUI
import AudioEngine
import Logging

struct RecordingWindow: View {
    @State var transcriptionString: TranscriptionString = {
        var container = AttributeContainer()
        container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = .pink.opacity(0.8)
        return TranscriptionString(volatileAttributes: container)
    }()
    
    @State var transcriptionSession: TranscriptionSession?
    @State var isTranscribing: Bool = false
    
    @State private var isCursorVisible = false

    var body: some View {
        Button("Start Recording") {
            Task {
                isTranscribing = true
                defer { isTranscribing = false }

                do {
                    transcriptionSession = try await TranscriptionSession(transcriptionString: transcriptionString)
                    try await transcriptionSession?.start()
                } catch {
                    Log.logger.error("Could not start recording", error: error)
                }
            }
        }
        
        Button("Stop Recording") {
            Task {
                isTranscribing = true
                defer { isTranscribing = false }

                do {
                    try await transcriptionSession?.stop()
                } catch {
                    Log.logger.error("Could not stop recording", error: error)
                }
            }
        }
    }
}

#Preview {
    RecordingWindow()
}
