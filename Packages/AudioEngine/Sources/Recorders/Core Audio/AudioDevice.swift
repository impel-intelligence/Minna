//
//  AudioDevice.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

/// A class that models and uniquely identifies base audio device objects.
class AudioDevice: Identifiable, Hashable, ObservableObject {
    let queue: DispatchQueue
    let id: AudioObjectID
    let uid: String
    
    init(id: AudioObjectID, queue: DispatchQueue = .main) {
        self.id = id
        
        // Get the UID of the device.
        self.uid = id.device.uid
        self.queue = queue
    }
    
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
