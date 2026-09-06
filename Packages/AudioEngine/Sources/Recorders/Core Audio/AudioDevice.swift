//
//  AudioDevice.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

/// A class that models and uniquely identifies base audio device objects.
class AudioDevice: Identifiable, Equatable, Hashable, ObservableObject {
    let dispatchQueue: DispatchQueue
    let id: AudioObjectID
    let uid: String
    
    init(id: AudioObjectID, dispatchQueue: DispatchQueue = .main) throws {
        self.id = id
        
        // Get the UID of the device.
        self.uid = try id.device.uid
        self.dispatchQueue = dispatchQueue
    }
    
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
