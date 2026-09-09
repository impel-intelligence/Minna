//
//  PropertyListener.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

/// Wraps a Core Audio property-listener and handles registration and de-registration.
class PropertyListener {
    let dispatchQueue: DispatchQueue
    let id: AudioObjectID
    let listenerToken: AudioObjectPropertyListenerBlock
    var propertyAddress: AudioObjectPropertyAddress

    init(id: AudioObjectID, selector: AudioObjectPropertySelector, dispatchQueue: DispatchQueue = .main, listener: @escaping AudioObjectPropertyListenerBlock) throws {
        self.dispatchQueue = dispatchQueue
        self.id = id
        propertyAddress = CoreAudio.getPropertyAddress(selector: selector)
        
        listenerToken = listener
        let addListenerStatus = AudioObjectAddPropertyListenerBlock(id, &propertyAddress, dispatchQueue, listener)
        try addListenerStatus.validateCoreAudioError()
    }
    
    deinit {
        do {
            let removeDeviceListenerStatus = AudioObjectRemovePropertyListenerBlock(id, &propertyAddress, dispatchQueue, listenerToken)
            try removeDeviceListenerStatus.validateCoreAudioError()
        } catch {
            Log.logger.error("Failed to remove property list listener block", error: error, metadata: ["id": "\(id)"])
        }
        
    }
}
