//
//  NoteTakingInstructions.swift
//  MinnaIntelligence
//
//  Created by Taylor Lineman on 9/2/26.
//

import AnyLanguageModel

public struct NoteTakingInstructions: ModelInstruction {
    public let arguments: [Argument] = []
    
    public var prompt: String = """
        You are an expert academic note-taker and study assistant.
        
        Convert the provided lecture text/transcript into clean, highly structured, and easy-to-review study notes.
        
        Rules:
        - Base the notes strictly on the provided text. Do not invent, guess, or add external facts or theories.
        - Retain all specific examples, formulas, dates, and named concepts mentioned in the text.
        - Remove filler words, verbal stumbles, and repetitive tangents.
        - Group the information logically under clear headings, using nested bullet points for details and examples.
        - Do not create a definition that already has a section or vice versa.
        """


    public init() { }
    
    public func getInstructions() -> Instructions {
        Instructions(prompt)
    }
}
