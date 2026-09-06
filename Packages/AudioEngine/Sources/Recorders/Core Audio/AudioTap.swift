//
//  AudioTap.swift
//  AudioEngine
//
//  Originally from Apple: https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps
//  Edited by Taylor Lineman on 9/6/26.
//

import CoreAudio

class AudioTap: Identifiable, Hashable, ObservableObject {
    let id: AudioObjectID
    public var config: TapConfig
        
    var descriptionAddress = CoreAudio.getPropertyAddress(selector: kAudioTapPropertyDescription)
    var descriptionChangedToken: AudioObjectPropertyListenerBlock?

    /// Initialize an `AudioTap` by storing the tap's unique identifier and description, and registering audio property listeners.
    /// - Tag: AudioTap
    init(id: AudioObjectID) {
        self.id = id
        
        // Get the description of the audio tap.
        let description: CATapDescription = self.id.tap.description
        
        // Fill out the tap config from the description.
        self.config = TapConfig(description: description)

        registerListeners()
    }
    
    deinit {
        unregisterListeners()
    }
    
    static func == (lhs: AudioTap, rhs: AudioTap) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func registerListeners() {
        let descriptionChanged: AudioObjectPropertyListenerBlock = { _, _ in
            // Get the description of the audio tap.
            let description: CATapDescription = self.id.tap.description
            
            // Fill out the tap config from the description.
            self.config = TapConfig(description: description)
        }
        
        AudioObjectAddPropertyListenerBlock(id, &descriptionAddress, DispatchQueue.main, descriptionChanged)
        descriptionChangedToken = descriptionChanged
    }
    
    func unregisterListeners() {
        guard let token = descriptionChangedToken else { return }
        
        AudioObjectRemovePropertyListenerBlock(id, &descriptionAddress, DispatchQueue.main, token)
        descriptionChangedToken = nil
    }
        
    func setTapDescription() {
        // Fill out a tap description with the saved tap configuration.
        var description = CATapDescription()
        description.name = self.config.name
        description.processes = Array(self.config.processes)
        description.isPrivate = self.config.isPrivate
        description.isProcessRestoreEnabled = self.config.isProcessRestoreEnabled
        description.muteBehavior = CATapMuteBehavior(rawValue: self.config.mute.rawValue) ?? description.muteBehavior
        description.isMixdown = self.config.mixdown == .mono || self.config.mixdown == .stereo
        description.isMono = self.config.mixdown == .mono
        description.isExclusive = self.config.exclusive
        description.deviceUID = self.config.device
        description.stream = self.config.streamIndex

        // Set the modified description on the tap object.
        withUnsafeMutablePointer(to: &description) { description in
            var propertyAddress = CoreAudio.getPropertyAddress(selector: kAudioTapPropertyDescription)
            let propertySize = UInt32(MemoryLayout<CATapDescription>.stride)
            AudioObjectSetPropertyData(self.id, &propertyAddress, 0, nil, propertySize, description)
        }
    }
}

extension AudioTap {
    /// Create a new process tap based on the provided tap description.
    /// - Tag: CreateTap
    static func new(config: TapConfig) -> AudioTap {
        // Create a tap description.
        let description = CATapDescription()
        
        // Fill out the description properties with the tap configuration from the UI.
        description.name = config.name
        description.processes = Array(config.processes)
        description.isPrivate = config.isPrivate
        description.muteBehavior = CATapMuteBehavior(rawValue: config.mute.rawValue) ?? description.muteBehavior
        description.isMixdown = config.mixdown == .mono || config.mixdown == .stereo
        description.isMono = config.mixdown == .mono
        description.isExclusive = config.exclusive
        description.deviceUID = config.device
        description.stream = config.streamIndex
        
        // Ask the HAL to create a new tap and put the resulting `AudioObjectID` in `tapID`.
        var tapID = AudioObjectID(kAudioObjectUnknown)
        AudioHardwareCreateProcessTap(description, &tapID)
        
        return AudioTap(id: tapID)
    }
}
