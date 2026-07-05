//
//  MinnaPrompt.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/5/26.
//

import AnyLanguageModel

public protocol ModelInstruction {
    static func getPrompt() -> Instructions
}
