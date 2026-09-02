//
//  MinnaPrompt.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/5/26.
//

import AnyLanguageModel

public struct Argument {
    public let title: String
    public let code: String
    public let type: Any.Type
    public let description: String
}

public protocol ModelInstruction {
    var prompt: String { get set }
    var arguments: [Argument] { get }
    
    func getInstructions() -> Instructions
}
