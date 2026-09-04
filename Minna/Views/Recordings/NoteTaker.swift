//
//  NoteTaker.swift
//  Minna
//
//  Created by Taylor Lineman on 9/1/26.
//

import SwiftUI
import AudioEngine
import Logging
import FoundationModels
import InfiniteGrid
import PromptManager

@Generable(description: "A section of notes based on a provided transcript.")
struct NoteBlock {
    @Generable
    struct Section: Hashable {
        @Guide(description: "The subject of a section, the overarching theme of the content")
        let subject: String
        @Guide(description: "The descriptive content of the section.")
        let content: String
    }

//    @Generable
//    struct Definition: Hashable {
//        @Guide(description: "The word, phrase, or concept that is being defined")
//        let concept: String
//        @Guide(description: "The description of the concept that is being defined")
//        let description: String
//                
//        func hash(into hasher: inout Hasher) {
//            hasher.combine(concept)
//            hasher.combine(description)
//        }
//    }
    
    @Guide(description: "Sections of content, produced from the provided transcription.")
    let sections: [Section]
//    @Guide(description: "Concepts with definitions, produced from the provided transcription.")
//    let definitions: [Definition]
}

@Generable(description: "A set of edits to perform to notes")
struct NoteEdits {
    @Generable
    enum Edit {
        case deleteSection(name: String)
        case replaceSection(name: String, newContent: String)
        case renameSection(name: String, newName: String)
        
//        case deleteDefinition(name: String)
//        case replaceDefinition(name: String, newContent: String)
//        case renameDefinition(name: String, newName: String)
    }
    
    @Guide(description: "A list of edits to perform to the notes. Deletes should only be used when the content deleted has been put into another section or definition.")
    var edits: [NoteEdits.Edit]
}

struct GetNoteSection: Tool {
    let name = "getNoteSection"
    let description = "Gets a specific note section by subject"
    
    let notes: [NoteBlock.Section]

    @Generable
    struct Arguments {
        let subject: String
    }

    func call(arguments: Arguments) async throws -> [String] {
        let output = notes.filter { $0.subject == arguments.subject }.map { section in
            return """
                SUCCESS
                # \(section.subject)
                \(section.content)
                """
        }
        print("Getting note \(arguments.subject) \(output)")
        return output
    }
}

//struct GetNoteDefinition: Tool {
//    let name = "getDefinition"
//    let description = "Gets a specific definition from a note"
//    
//    let definitions: [NoteBlock.Definition]
//
//    @Generable
//    struct Arguments {
//        let concept: String
//    }
//
//    func call(arguments: Arguments) async throws -> [String] {
//        let output = definitions.filter { $0.concept == arguments.concept }.map { section in
//            return """
//                SUCCESS
//                # \(section.concept)
//                \(section.description)
//                """
//        }
//        print("Getting definition \(arguments.concept): \(output)")
//        return output
//    }
//}

// TODO: Take foundation functions off of the @MainActor that this is bound too by TranscriptionOutput.
@MainActor @Observable
final class NoteTaker: TranscriptionOutput {
    /// The maximum size of a chunk of notes to be submitted to the model. Found by counting the instructions (15c, and the NoteBlock 307c)
    let maxChunkSize: Int = 2000
    
    var sections: [NoteBlock.Section] = []
//    var definitions: [NoteBlock.Definition] = []
    
    var waitingString: String = ""

    var noteContinuation: AsyncStream<String>.Continuation?
    var consumeQueueTask: Task<Void, Never>?
    
    var combinationTimer: Timer?
    
    var previouslyEditedSectionHash: Int = 0
    var previouslyEditedDefinitionsHash: Int = 0
    
    var combiningNotes: Bool = false

    init() {
        combinationTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [self] _ in
            Task { @MainActor in
                do {
                    try await self.combineNotes()
                } catch {
                    Log.logger.error("Failed to stream audio into transcriber", error: error)
                }
            }
        }
    }
    
    private func combineNotes() async throws {
        guard !self.combiningNotes else { return }
        self.combiningNotes = true
        defer { self.combiningNotes = false }
        
        guard !sections.isEmpty else { return }
        guard sections.hashValue != previouslyEditedSectionHash else { return }
//        guard definitions.hashValue != previouslyEditedDefinitionsHash else { return }
        
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            Log.logger.error("Apple Intelligence is not available")
            return
        }

        let instructions = Instructions(NoteCompactionInstructions().prompt)
        
        // Edited by Claude Sonnet 4.6 (Anthropic) on 2026-09-01
        // Snapshot before await — updateNotes can append during the model call
        var editedSections = self.sections
//        var editedDefinitions = self.definitions
       
        let snapshotSectionSubjects = Set(editedSections.map { $0.subject })
//        let snapshotDefinitionConcepts = Set(editedDefinitions.map { $0.concept })

        let existingSubjects = editedSections.map { $0.subject }.joined(separator: ", ")
//        let existingDefinitions = editedDefinitions.map { $0.concept }.joined(separator: ", ")

        let input = """
            Existing Subjects: \(existingSubjects)
            """
        // Existing Definitions: \(existingDefinitions)
        
        let tools: [any Tool] = [
            GetNoteSection(notes: editedSections),
//            GetNoteDefinition(definitions: editedDefinitions)
        ]

        Log.logger.info("Starting to edit...")

        let session: LanguageModelSession = LanguageModelSession(tools: tools, instructions: instructions)
        let response = try await session.respond(
            to: input,
            generating: NoteEdits.self
        )

        Log.logger.info("Got edits \(response.content.edits.count)")

        for edit in response.content.edits {
            switch edit {
            case .deleteSection(let name):
                Log.logger.info("Deleting section \(name)")
                editedSections = editedSections.filter { $0.subject != name }
            case .replaceSection(let name, let newContent):
                Log.logger.info("Replacing section \(name)")
                editedSections = editedSections.map { $0.subject == name ? NoteBlock.Section(subject: name, content: newContent) : $0 }
            case .renameSection(let name, let newName):
                Log.logger.info("Renaming section \(name) to \(newName)")
                editedSections = editedSections.map { $0.subject == name ? NoteBlock.Section(subject: newName, content: $0.content) : $0 }
//            case .deleteDefinition(let name):
//                Log.logger.info("Deleting definition \(name)")
//                editedDefinitions = editedDefinitions.filter { $0.concept != name }
//            case .replaceDefinition(let name, let newContent):
//                Log.logger.info("Replacing definition \(name)")
//                editedDefinitions = editedDefinitions.map { $0.concept == name ? NoteBlock.Definition(concept: name, description: newContent) : $0 }
//            case .renameDefinition(let name, let newName):
//                Log.logger.info("Renaming definition \(name) to \(newName)")
//                editedDefinitions = editedDefinitions.map { $0.concept == name ? NoteBlock.Definition(concept: newName, description: $0.description) : $0 }
            }
        }

        // Merge edited snapshot with any items appended by updateNotes during the model call
        sections = editedSections + sections.filter { !snapshotSectionSubjects.contains($0.subject) }
//        definitions = editedDefinitions + definitions.filter { !snapshotDefinitionConcepts.contains($0.concept) }
        
        previouslyEditedSectionHash = editedSections.hashValue
//        previouslyEditedDefinitionsHash = editedDefinitions.hashValue
    }
    
    func startNoteTaking() {
        let (noteStream, noteContinuation) = AsyncStream.makeStream(of: String.self)
        self.noteContinuation = noteContinuation
        
        consumeQueueTask = Task {
            for await chunk in noteStream {
                do {
                    try await updateNotes(with: chunk)
                } catch {
                    // TODO: This drops notes if chunks are too big, can use the model token counter to split chunks
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

        let instructions = Instructions(NoteTakingInstructions().prompt)
        let session: LanguageModelSession = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: content, generating: NoteBlock.self)
        sections.append(contentsOf: response.content.sections)
//        definitions.append(contentsOf: response.content.definitions)
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
