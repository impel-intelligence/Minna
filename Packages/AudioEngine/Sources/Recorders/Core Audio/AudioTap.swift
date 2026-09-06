//
//  AudioTap.swift
//  AudioEngine
//
//  Originally from Apple: https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps
//  Edited by Taylor Lineman on 9/6/26.
//

import CoreAudio

class AudioTap: Identifiable, Equatable, Hashable, ObservableObject {
    let dispatchQueue: DispatchQueue
    let id: AudioObjectID
    public var config: TapConfig
        
    var descriptionAddress = CoreAudio.getPropertyAddress(selector: kAudioTapPropertyDescription)
    var descriptionChangedToken: AudioObjectPropertyListenerBlock?

    /// Initialize an `AudioTap` by storing the tap's unique identifier and description, and registering audio property listeners.
    /// - Tag: AudioTap
    init(id: AudioObjectID, dispatchQueue: DispatchQueue = .main) {
        self.id = id
        self.dispatchQueue = dispatchQueue
        
        // Get the description of the audio tap.
        let description: CATapDescription = self.id.tap.description
        
        // Fill out the tap config from the description.
        self.config = TapConfig(description: description)

        registerListeners()
    }
    
    deinit {
        unregisterListeners()
        AudioHardwareDestroyProcessTap(id)
    }
    
    static func == (lhs: AudioTap, rhs: AudioTap) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func registerListeners() {
        let descriptionChanged: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            // Get the description of the audio tap.
            guard let description: CATapDescription = self?.id.tap.description else { return }
            
            // Fill out the tap config from the description.
            self?.config = TapConfig(description: description)
        }
        
        AudioObjectAddPropertyListenerBlock(id, &descriptionAddress, dispatchQueue, descriptionChanged)
        descriptionChangedToken = descriptionChanged
    }
    
    func unregisterListeners() {
        guard let token = descriptionChangedToken else { return }
        
        AudioObjectRemovePropertyListenerBlock(id, &descriptionAddress, dispatchQueue, token)
        descriptionChangedToken = nil
    }
        
    func setTapDescription() {
        // Fill out a tap description with the saved tap configuration.
        var description = config.description

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
    static func new(config: TapConfig) -> AudioTap {
        // Create a tap description.
        let description = config.description
        
        // Ask the HAL to create a new tap and put the resulting `AudioObjectID` in `tapID`.
        var tapID = AudioObjectID.unknown
        AudioHardwareCreateProcessTap(description, &tapID)
        
        return AudioTap(id: tapID)
    }
}
