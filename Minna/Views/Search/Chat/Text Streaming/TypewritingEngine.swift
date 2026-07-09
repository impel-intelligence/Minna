//
//  TypewritingEngine.swift
//  Minna
//
//  Created by Taylor Lineman on 7/6/26.
//

import SwiftUI

@Observable @MainActor
final class TypewritingEngine {
    /// The text that has been typed out by the typewriter. The view utilizing the typewriter should bind their text view to this.
    private(set) var displayedText: String = ""
    
    /// How many characters should be displayed per tick.
    private var charactersPerTick: Int = 5
    private var catchUpDivisor: Int = 10
    
    /// 33ms is ~ 30fps ((1000 ms / 30 frames) = 1 frame every 33 ms)
    private var tickInterval: Duration = .milliseconds(33)
    
    private var completeText: String = ""
    private var revealedCharacters: Int = 0
    
    private var hasStartedAnimation: Bool = false
    private var characterDrainTask: Task<Void, Never>?
    
    func update(with text: String, isStreaming: Bool) {
        completeText = text
        
        if isStreaming { hasStartedAnimation = true }

        // Only animate when the text is streaming, and there are still characters left to reveal.
        guard hasStartedAnimation && revealedCharacters < completeText.count else {
            revealedCharacters = completeText.count
            displayedText = String(completeText.prefix(revealedCharacters))
            return
        }
        
        revealedCharacters = min(revealedCharacters, completeText.count)
        
        // Update the displayed text to the new number of revealed characters.
        displayedText = String(completeText.prefix(revealedCharacters))
        startTextDrain()
    }
    
    private func startTextDrain() {
        // Don't duplicate an existing drain
        guard characterDrainTask == nil else { return }
        characterDrainTask = Task { [weak self] in
            await self?.drain()
        }
    }
    
    private func drain() async {
        while !Task.isCancelled {
            let charactersNeedingDisplay = completeText.count - revealedCharacters
            
            guard charactersNeedingDisplay > 0 else {
                characterDrainTask = nil
                return
            }
            
            // Variable step in case a lot of text comes in at once. To keep up we want to adjust the step to go quicker.
            let step = max(charactersPerTick, charactersNeedingDisplay / catchUpDivisor)
            
            revealedCharacters = min(completeText.count, revealedCharacters + step)
            
            // Actually display the text.
            displayedText = String(completeText.prefix(revealedCharacters))
            
            try? await Task.sleep(for: tickInterval)
        }
    }
}
