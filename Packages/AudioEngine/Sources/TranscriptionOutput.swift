//
//  TranscriptionOutput.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/30/26.
//

import Foundation

@MainActor
public protocol TranscriptionOutput: Observable, Sendable {
    func submitVolatile(string: AttributedString)
    func submitFinalized(string: AttributedString)
}
