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
    init(id: AudioObjectID, dispatchQueue: DispatchQueue = .main) throws {
        self.id = id
        self.dispatchQueue = dispatchQueue
        
        // Get the description of the audio tap.
        let description: CATapDescription = try self.id.tap.description
        
        // Fill out the tap config from the description.
        self.config = TapConfig(description: description)

        try registerListeners()
    }
    
    deinit {
        do {
            try unregisterListeners()
        } catch {
            Log.logger.error("Failed to unregister audio tap", error: error, metadata: ["tapID": "\(id)"])
        }
        
        do {
            let status = AudioHardwareDestroyProcessTap(id)
            try status.validateCoreAudioError()
        } catch {
            Log.logger.error("Failed to destroy process tap", error: error, metadata: ["tapID": "\(id)"])
        }
    }
    
    static func == (lhs: AudioTap, rhs: AudioTap) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func registerListeners() throws {
        let descriptionChanged: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            do {
                // Get the description of the audio tap.
                guard let description: CATapDescription = try self?.id.tap.description else { return }
                
                // Fill out the tap config from the description.
                self?.config = TapConfig(description: description)
            } catch {
                Log.logger.error("Failed to get audio description", error: error, metadata: ["tapID": "\(self?.id ?? .unknown)"])
            }
        }
        
        AudioObjectAddPropertyListenerBlock(id, &descriptionAddress, dispatchQueue, descriptionChanged)
        descriptionChangedToken = descriptionChanged
    }
    
    func unregisterListeners() throws {
        guard let token = descriptionChangedToken else { return }
        
        let status = AudioObjectRemovePropertyListenerBlock(id, &descriptionAddress, dispatchQueue, token)
        descriptionChangedToken = nil
        
        try status.validateCoreAudioError()
    }
        
    func setTapDescription() throws {
        // Fill out a tap description with the saved tap configuration.
        var description = config.description

        // Set the modified description on the tap object.
        let status = withUnsafeMutablePointer(to: &description) { description in
            var propertyAddress = CoreAudio.getPropertyAddress(selector: kAudioTapPropertyDescription)
            let propertySize = UInt32(MemoryLayout<CATapDescription>.stride)
            return AudioObjectSetPropertyData(self.id, &propertyAddress, 0, nil, propertySize, description)
        }
        
        try status.validateCoreAudioError()
    }
}

extension AudioTap {
    /// Create a new process tap based on the provided tap description.
    static func new(config: TapConfig) throws -> AudioTap {
        // Create a tap description.
        let description = config.description
        
        // Ask the HAL to create a new tap and put the resulting `AudioObjectID` in `tapID`.
        var tapID = AudioObjectID.unknown
        let status = AudioHardwareCreateProcessTap(description, &tapID)
        try status.validateCoreAudioError()
        
        return try AudioTap(id: tapID)
    }
}
