//
//  AggregateDevice.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

/// A class that models aggregate device objects, registers audio property listeners, and maintains lists of subdevices and subtaps.
class AggregateDevice: AudioDevice {
    let name: String
    
    var deviceList: Set<String> = []
    var tapList: Set<String> = []
    var isPrivate: Bool = false
    var autoStart: Bool = false
    /// Stop IO automatically if all tapped processes stop.
    var autoStop: Bool = false
    var isRecording: Bool = false
    
    var deviceListAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyFullSubDeviceList)
    var tapListAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyTapList)
    var compositionAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
    var propertiesChangedToken: AudioObjectPropertyListenerBlock?
    
    override init(id: AudioObjectID, dispatchQueue: DispatchQueue = .main) throws {
        // Get the name of the aggregate device.
        self.name = try id.name

        try super.init(id: id, dispatchQueue: dispatchQueue)
        
        // Fill out the device and tap lists.
        try self.updateDeviceList()
        try self.updateTapList()
        
        try registerListeners()
    }
    
    deinit {
        unregisterListeners()
        
        do {
            let status = AudioHardwareDestroyAggregateDevice(id)
            try status.validateCoreAudioError()
        } catch {
            Log.logger.error("Failed to destroy aggregate device", error: error, metadata: ["tapID": "\(id)"])
        }
    }
    
    func registerListeners() throws {
        let propertiesChanged: AudioObjectPropertyListenerBlock = { [weak self] inNumberAddresses, inAddresses in
            for index in 0..<inNumberAddresses {
                let address = inAddresses[Int(index)]
                do {
                    switch address.mSelector {
                    case kAudioAggregateDevicePropertyFullSubDeviceList:
                        try self?.updateDeviceList()
                    case kAudioAggregateDevicePropertyTapList:
                        try self?.updateTapList()
                    case kAudioAggregateDevicePropertyComposition:
                        try self?.updateConfig()
                    default:
                        break
                    }
                } catch {
                    Log.logger.error("Failed to observe property list changed", error: error, metadata: ["deviceID": "\(self?.id ?? .unknown)"])
                }
            }
        }
        
        let addDeviceListenerStatus = AudioObjectAddPropertyListenerBlock(id, &deviceListAddress, dispatchQueue, propertiesChanged)
        let addTapListenerStatus = AudioObjectAddPropertyListenerBlock(id, &tapListAddress, dispatchQueue, propertiesChanged)
        let addCompositionListenerStatus = AudioObjectAddPropertyListenerBlock(id, &compositionAddress, dispatchQueue, propertiesChanged)
        
        
        propertiesChangedToken = propertiesChanged

        do {
            try addDeviceListenerStatus.validateCoreAudioError()
            try addTapListenerStatus.validateCoreAudioError()
            try addCompositionListenerStatus.validateCoreAudioError()
        } catch {
            unregisterListeners()
        }
    }
    
    func unregisterListeners() {
        guard let token = propertiesChangedToken else { return }
            
        let removeDeviceListenerStatus = AudioObjectRemovePropertyListenerBlock(id, &deviceListAddress, dispatchQueue, token)
        let removeTapListenerStatus = AudioObjectRemovePropertyListenerBlock(id, &tapListAddress, dispatchQueue, token)
        let removeCompositionListenerStatus = AudioObjectRemovePropertyListenerBlock(id, &compositionAddress, dispatchQueue, token)
        
        let removeDeviceListenerError = CoreAudioError(status: removeDeviceListenerStatus)
        if removeDeviceListenerError == .noError {
            Log.logger.info("Failed to remove device list listener", error: removeDeviceListenerError, metadata: ["deviceID": "\(id)"])
        }
        
        let removeTapListenerError = CoreAudioError(status: removeTapListenerStatus)
        if removeTapListenerError == .noError {
            Log.logger.info("Failed to remove tap list listener", error: removeTapListenerError, metadata: ["deviceID": "\(id)"])
        }

        
        let removeCompositionListenerError = CoreAudioError(status: removeCompositionListenerStatus)
        if removeCompositionListenerError == .noError {
            Log.logger.info("Failed to remove composition listener", error: removeCompositionListenerError, metadata: ["deviceID": "\(id)"])
        }
        
        propertiesChangedToken = nil
    }
    
    func updateDeviceList() throws {
        // Get the device list of the aggregate device.
        self.deviceList = []
                
        var propertySize: UInt32 = 0
        let propertySizeStatus = AudioObjectGetPropertyDataSize(self.id, &deviceListAddress, 0, nil, &propertySize)
        try propertySizeStatus.validateCoreAudioError()
        
        var list: CFArray? = nil
        let dataStatus = withUnsafeMutablePointer(to: &list) { [id] list in
            AudioObjectGetPropertyData(id, &deviceListAddress, 0, nil, &propertySize, list)
        }
        try dataStatus.validateCoreAudioError()

        for uid in list as? [CFString] ?? [] {
            self.deviceList.insert(uid as String)
        }
    }
    
    func updateTapList() throws {
        // Get the tap list of the aggregate device.
        self.tapList = Set<String>()
        var propertySize: UInt32 = 0
        let propertySizeStatus = AudioObjectGetPropertyDataSize(self.id, &tapListAddress, 0, nil, &propertySize)
        try propertySizeStatus.validateCoreAudioError()
        
        var list: CFArray? = nil
        
        let dataStatus = withUnsafeMutablePointer(to: &list) { [id] list in
            AudioObjectGetPropertyData(id, &tapListAddress, 0, nil, &propertySize, list)
        }
        try dataStatus.validateCoreAudioError()
        
        for uid in list as? [CFString] ?? [] {
            self.tapList.insert(uid as String)
        }
    }
    
    func updateConfig() throws {
        // Get the aggregate device composition dictionary.
        var propertySize: UInt32 = 0
        var propertyAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
        
        let propertySizeStatus = AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        try propertySizeStatus.validateCoreAudioError()
        
        var composition: CFDictionary? = nil
        
        let dataStatus = withUnsafeMutablePointer(to: &composition) { [id] composition in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, composition)
        }
        try dataStatus.validateCoreAudioError()

        if let compositionDict = composition as? [String: AnyObject] {
            self.isPrivate = compositionDict[kAudioAggregateDeviceIsPrivateKey] as? Bool ?? self.isPrivate
            self.autoStart = compositionDict[kAudioAggregateDeviceTapAutoStartKey] as? Bool ?? self.autoStart
        }
    }
    
    func setPrivate(isPrivate: Bool) throws {
        // Get the aggregate device composition dictionary.
        var propertySize: UInt32 = 0
        var propertyAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
        
        let propertySizeStatus = AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        try propertySizeStatus.validateCoreAudioError()
        
        var composition: CFDictionary? = nil
        let dataStatus = withUnsafeMutablePointer(to: &composition) { [id] composition in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, composition)
        }
        try dataStatus.validateCoreAudioError()
        
        if var compositionDict = composition as? [String: AnyObject] {
            compositionDict[kAudioAggregateDeviceIsPrivateKey] = isPrivate as NSNumber
            // Set the composition back on the aggregate device.
            composition = compositionDict as CFDictionary
            
            let compositionDataStatus = withUnsafeMutablePointer(to: &composition) {  [id] composition in
                AudioObjectSetPropertyData(id, &propertyAddress, 0, nil, propertySize, composition)
            }
            try compositionDataStatus.validateCoreAudioError()
        }
    }
    
    func setAutoStart(autostart: Bool) throws {
        // Get the aggregate device composition dictionary.
        var propertySize: UInt32 = 0
        var propertyAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
        let propertySizeStatus = AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        try propertySizeStatus.validateCoreAudioError()
        
        var composition: CFDictionary? = nil
        let dataStatus = withUnsafeMutablePointer(to: &composition) { [id] composition in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, composition)
        }
        try dataStatus.validateCoreAudioError()

        if var compositionDict = composition as? [String: AnyObject] {
            compositionDict[kAudioAggregateDeviceTapAutoStartKey] = autostart as NSNumber
            // Set the composition back on the aggregate device.
            composition = compositionDict as CFDictionary
            
            let compositionDataStatus = withUnsafeMutablePointer(to: &composition) { [id] composition in
                AudioObjectSetPropertyData(id, &propertyAddress, 0, nil, propertySize, composition)
            }
            
            try compositionDataStatus.validateCoreAudioError()
        }
    }
    
    func addSubDevice(uid: String) throws {
        try addRemove(uid: uid, action: .add, type: .device)
    }

    func removeSubDevice(uid: String) throws {
        try addRemove(uid: uid, action: .remove, type: .device)
    }

    func addSubTap(uid: String) throws {
        try addRemove(uid: uid, action: .add, type: .tap)
    }

    func removeSubTap(uid: String) throws {
        try addRemove(uid: uid, action: .remove, type: .tap)
    }
    
    private enum ModifyAction: Int {
        case add = 0
        case remove = 1
    }
    
    private enum ListType: Int {
        case device = 0
        case tap = 1
    }
    
    /// Add or remove a subdevice or subtap from the aggregate device.
    private func addRemove(uid: String, action: ModifyAction, type: ListType) throws {
        var propertyAddress: AudioObjectPropertyAddress
        if type == .device {
            // Use the aggregate subdevice list address.
            propertyAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyFullSubDeviceList)
        } else {
            // Use the aggregate device tap list address.
            propertyAddress = CoreAudio.getPropertyAddress(selector: kAudioAggregateDevicePropertyTapList)
        }

        var propertySize: UInt32 = 0
        let propertySizeStatus = AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        try propertySizeStatus.validateCoreAudioError()

        var list: CFArray? = nil
        let dataStatus = withUnsafeMutablePointer(to: &list) { [id] list in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, list)
        }

        try dataStatus.validateCoreAudioError()
        
        if var listAsArray = list as? [CFString] {
            if action == .add {
                // Add the new object ID if it's not already in the list.
                if !listAsArray.contains(uid as CFString) {
                    listAsArray.append(uid as CFString)
                    propertySize += UInt32(MemoryLayout<CFString>.stride)
                }
            } else {
                // Remove the object ID if it's in the list.
                if let index = listAsArray.firstIndex(of: uid as CFString) {
                    listAsArray.remove(at: index)
                }
            }

            // Set the list back on the aggregate device.
            list = listAsArray as CFArray
            let setStatus = withUnsafeMutablePointer(to: &list) { [id] list in
                AudioObjectSetPropertyData(id, &propertyAddress, 0, nil, propertySize, list)
            }
            try setStatus.validateCoreAudioError()
        }
    }
}
