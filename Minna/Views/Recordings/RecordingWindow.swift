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

@Generable(description: "A section of notes based on a provided transcript.")
struct NoteBlock {
    @Generable
    struct Section {
        @Guide(description: "The subject of a section, the overarching theme of the content")
        let subject: String
        @Guide(description: "The descriptive content of the section.")
        let content: String
    }

    @Generable
    struct Definition {
        @Guide(description: "The word, phrase, or concept that is being defined")
        let concept: String
        @Guide(description: "The description of the concept that is being defined")
        let description: String
    }
    
    @Guide(description: "Sections of content, produced from the provided transcription.")
    let sections: [Section]
    @Guide(description: "Concepts with definitions, produced from the provided transcription.")
    let definitions: [Definition]
}

@Observable
final class NoteTaker: TranscriptionOutput {
    /// The maximum size of a chunk of notes to be submitted to the model. Found by counting the instructions (15c, and the NoteBlock 307c)
    let maxChunkSize: Int = 2000
    
    var sections: [NoteBlock.Section] = []
    var definitions: [NoteBlock.Definition] = []
    
    var waitingString: String = ""

    var noteContinuation: AsyncStream<String>.Continuation?
    var consumeQueueTask: Task<Void, Never>?
    
    init() { }
    
    func startNoteTaking() {
        let (noteStream, noteContinuation) = AsyncStream.makeStream(of: String.self)
        self.noteContinuation = noteContinuation
        
        consumeQueueTask = Task {
            for await chunk in noteStream {
                do {
                    try await updateNotes(with: chunk)
                } catch {
                    Log.logger.error("Failed to stream audio into transcriber", error: error)
                }
            }
        }
    }
    
    func updateNotes(with content: String) async throws {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            Log.logger.error("Apple Intelligence is not available")
            return
        }
        
        let instructions = "Break this transcript into academic notes."
        let session: LanguageModelSession = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: content, generating: NoteBlock.self)
        sections.append(contentsOf: response.content.sections)
        definitions.append(contentsOf: response.content.definitions)
    }
    
    // no-op we don't care about volatile results
    func submitVolatile(string: AttributedString) { }
    
    func submitFinalized(string: AttributedString) {
        waitingString.append(String(string.characters))
        
        if waitingString.count > maxChunkSize {
            let chunk = chunk(string: waitingString, size: maxChunkSize)
            waitingString.removeFirst(chunk.count)
            noteContinuation?.yield(chunk)
        }
    }
    
    //  Claude Sonnet 4.6 (Anthropic) on 2026-08-30
    private func chunk(string: String, size: Int) -> String {
        var lastCut = string.startIndex
        var searchFrom = string.startIndex
        while let dotRange = string.range(of: ".", range: searchFrom..<string.endIndex) {
            guard string.distance(from: string.startIndex, to: dotRange.upperBound) <= size else { break }
            lastCut = dotRange.upperBound
            searchFrom = dotRange.upperBound
        }
        return String(string[..<lastCut])
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

    var body: some View {
        VStack {
            HStack {
                Button("Start Recording") {
                    Task {
                        isTranscribing = true
                        defer { isTranscribing = false }
                        
                        do {
                            transcriptionSession = try await TranscriptionSession(outputs: [
                                transcriptionString, // For UI Updates
                                noteTaker // For note taking
                            ])
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
            ScrollView {
                Text(transcriptionString.displayString)
                Text("(\(noteTaker.waitingString.count))" + noteTaker.waitingString)

                ForEach(noteTaker.sections, id: \.subject) { section in
                    NoteSectionView(section: section)
                }
                ForEach(noteTaker.definitions, id: \.concept) { definition in
                    VStack {
                        Text(definition.concept)
                        Text(definition.description)
                    }
                }
            }
        }
        .task {
            noteTaker.startNoteTaking()
        }
    }
}

#Preview {
    RecordingWindow()
}
