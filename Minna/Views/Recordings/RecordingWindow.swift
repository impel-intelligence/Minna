//
//  RecordingWindow.swift
//  Minna
//
//  Created by Taylor Lineman on 8/26/26.
//

import SwiftUI
import AudioEngine
import Logging
import FoundationModels
import InfiniteGrid
import SFSafeSymbols

extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

struct RecordingWindow: View {
    @State var transcriptionString: TranscriptionString = {
        var container = AttributeContainer()
        container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = .pink.opacity(0.8)
        return TranscriptionString(volatileAttributes: container)
    }()
    
    @State var noteTaker: NoteTaker = NoteTaker()
    @State var transcriptionSession: TranscriptionSession?
    @State var isTranscribing: Bool = false
    
    @State private var isCursorVisible = false

    @State var translation: CGPoint = .zero
    @State var scale: CGFloat = 1
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CanvasView(translation: $translation, scale: $scale) {
                ForEach(noteTaker.sections, id: \.subject) { section in
                    DraggableView(scale: $scale) {
                        NoteSectionView(section: section)
                    }
                }
//                ForEach(noteTaker.definitions, id: \.concept) { definition in
//                    DraggableView(scale: $scale) {
//                        NoteDefinitionView(defintion: definition)
//                    }
//                }
            }
            HStack {
                Spacer()
                Text("X: \(translation.x), Y: \(translation.y)")
                    .glassEffect()
            }
            GlassEffectContainer {
                VStack(spacing: 5) {
                    Button {
                        if isTranscribing {
                            isTranscribing = false

                            Task {
                                do {
                                    try await transcriptionSession?.stop()
                                } catch {
                                    Log.logger.error("Failed to stop transcription", error: error)
                                    isTranscribing = true
                                }
                            }
                        } else {
                            isTranscribing = true

                            Task {
                                do {
                                    try await startRecording()
                                } catch {
                                    Log.logger.error("Failed to start transcription", error: error)
                                    isTranscribing = false
                                }
                            }

                        }
                        
                    } label: {
                        HStack {
                            Image(systemSymbol: .microphone)
                                .accessibilityHidden(true)
                                .symbolEffect(.bounce, value: isTranscribing)
                            Text(isTranscribing ? "Now Recording" : "Transcribe Audio")
                        }
                        .foregroundStyle(isTranscribing ? .white : .primary)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .glassEffect(
                            .regular.tint(isTranscribing ? .red.opacity(0.75) : nil).interactive(),
                            in: .rect(cornerRadius: 12)
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    
                    if isTranscribing {
                        VStack(alignment: .leading) {
                            if noteTaker.waitingString.isEmpty {
                                Text("Waiting on transcription...")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)

                            } else {
                                Text("Transcription")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)

                                Text(noteTaker.waitingString)
                            }
                        }
                        .padding(5)
                        .frame(maxWidth: .infinity)
                        .glassEffect(
                            .regular.interactive(),
                            in: .rect(cornerRadius: 12)
                        )
                    }
                }
                .frame(width: 250)
                .padding(10)
            }
            .animation(.default, value: isTranscribing)
        }
        .onDisappear {
            Task {
                do {
                    try await transcriptionSession?.stop()
                } catch {
                    Log.logger.error("Failed to stop transcription", error: error)
                    isTranscribing = true
                }
            }
        }
    }
    
    func startRecording() async throws {
        noteTaker.startNoteTaking()
        
        transcriptionSession = try await TranscriptionSession(outputs: [
            transcriptionString, // For UI Updates
            noteTaker // For note taking
        ])
        try await transcriptionSession?.start()
    }
}

#Preview {
    RecordingWindow()
}

/*
 HStack {
                 try await transcriptionSession?.stop()
                 isTranscribing = false
             } catch {
                 isTranscribing = false
                 Log.logger.error("Could not stop recording", error: error)
             }
         }
     }
     .disabled(!isTranscribing)
 }

 */
