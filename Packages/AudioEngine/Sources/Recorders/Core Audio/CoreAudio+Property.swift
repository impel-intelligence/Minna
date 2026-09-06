//
//  CoreAudio.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

enum CoreAudio {
    static func getPropertyAddress(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal, element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
    }
}

