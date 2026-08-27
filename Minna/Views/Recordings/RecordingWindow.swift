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
    var body: some View {
        Button("Start Recording") {
            Task {
                do {
                    let session = try await TranscriptionSession()
                    try await session.start()
                } catch {
                    Log.logger.error("Could not start recording", error: error)
                }
            }
        }
    }
}

#Preview {
    RecordingWindow()
}
