//
//  AudioString.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 8/27/26.
//

import Foundation
import CoreMedia
import AppKit
import SwiftUI

enum VolatileAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = Bool
    static let name: String = "volatile"
}


extension AttributeScopes {
    struct AudioEngineAttributes: AttributeScope {
        let volatile: VolatileAttribute
    }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.AudioEngineAttributes, T>) -> T {
        self[T.self]
    }
}

@MainActor @Observable
public class TranscriptionString: TranscriptionOutput {
    public var displayString: AttributedString = AttributedString()
    public let volatileAttributes: AttributeContainer
    
    public init(volatileAttributes: AttributeContainer) {
        self.volatileAttributes = volatileAttributes
    }
    
    public func submitVolatile(string: AttributedString) {
        // Remove any existing volatile parts of the display string.
        removeVolatile()
        var mutableString = string
        mutableString.volatile = true
        mutableString.mergeAttributes(volatileAttributes)
        
        displayString += mutableString
    }
    
    public func submitFinalized(string: AttributedString) {
        // Remove the volatile range that is tacked onto the end of the string
        removeVolatile()
        displayString += string
        
        for run in displayString.runs {
            let confidence = run.transcriptionConfidence ?? 1
            var container = AttributeContainer()
            container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = .black.opacity(confidence)

            displayString[run.range].mergeAttributes(container)
        }
    }
    
    func removeVolatile() {
        // Traverses backwards through the array to grab the most recent volatile run. There will only ever be 1 volatile range and it will be the most recent run.
        guard let volatileRun = displayString.runs.last(where: { $0.volatile ?? false }) else { return }
        displayString.removeSubrange(volatileRun.range)
    }
}
