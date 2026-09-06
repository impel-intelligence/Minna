//
//  AudioObjectID.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

/// A protocol that marks an object as initializable through `init()`
protocol Initializable {
    init()
}

extension CATapDescription: Initializable { }
extension AudioStreamBasicDescription: Initializable { }
extension Int32: Initializable { }

extension AudioObjectID {
    /// The system audio object ID, `kAudioObjectSystemObject`
    static var systemID: Int32 { kAudioObjectSystemObject }
    
    /// The system audio object
    static var system: AudioObjectID { AudioObjectID(systemID) }
    
    /// The system audio object ID, `kAudioObjectSystemObject`
    static var unknownID: UInt32 { kAudioObjectUnknown }

    static var unknown: AudioObjectID { AudioObjectID(unknownID) }
}

extension AudioObjectID {
    func readArray(selector: AudioObjectPropertySelector) -> [AudioObjectID] {
        var listAddress: AudioObjectPropertyAddress = CoreAudio.getPropertyAddress(selector: selector)

        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(self, &listAddress, 0, nil, &propertySize)
        let processCount = Int(propertySize) / MemoryLayout<AudioObjectID>.stride
        var list: [AudioObjectID] = [AudioObjectID](repeating: 0, count: processCount)
        AudioObjectGetPropertyData(self, &listAddress, 0, nil, &propertySize, &list)
        
        return list
    }
    
    /// Retrieve list of audio processes from the HAL system.
    static func systemProcessList() -> [AudioObjectID] {
        return AudioObjectID.system.readArray(selector: kAudioHardwarePropertyProcessObjectList)
    }

    /// Retrieve list of audio taps from the HAL system.
    static func systemTapList() -> [AudioObjectID] {
        return AudioObjectID.system.readArray(selector: kAudioHardwarePropertyTapList)
    }
    
    
}

extension AudioObjectID {
    func readString(property: AudioObjectPropertySelector) -> String {
        var propertyAddress = CoreAudio.getPropertyAddress(selector: property)
        var propertySize = UInt32(MemoryLayout<CFString>.stride)
        var cfString: CFString = "" as CFString
        _ = withUnsafeMutablePointer(to: &cfString) { ptr in
            AudioObjectGetPropertyData(self, &propertyAddress, 0, nil, &propertySize, ptr)
        }
        return cfString as String
    }
    
    func read<T: Initializable>(property: AudioObjectPropertySelector) -> T {
        var propertyAddress = CoreAudio.getPropertyAddress(selector: property)
        var propertySize = UInt32(MemoryLayout<T>.stride)
        var item: T = T()
        _ = withUnsafeMutablePointer(to: &item) { ptr in
            AudioObjectGetPropertyData(self, &propertyAddress, 0, nil, &propertySize, ptr)
        }
        return item as T
    }

    
    var name: String { readString(property: kAudioObjectPropertyName) }
    
    /// A tap structure that has getters for CoreAudio property addressees. Could also be a weak var with a Tap class if we need to track the property addresses or tokens.
    var tap: Tap { Tap(id: self) }
    
    struct Tap {
        let id: AudioObjectID
        
        var description: CATapDescription { id.read(property: kAudioTapPropertyDescription) }
        
        var uid: String { id.readString(property: kAudioTapPropertyUID) }
        
        var format: (channelCount: UInt32, sampleRate: Int) {
            let streamDescription: AudioStreamBasicDescription = id.read(property: kAudioTapPropertyFormat)
            let channelCount = streamDescription.mChannelsPerFrame
            let sampleRate = Int(streamDescription.mSampleRate)
            
            return (channelCount, sampleRate)
        }
    }
    
    /// A process structure that has getters for CoreAudio property addressees. Could also be a weak var with a Process class if we need to track the property addresses or tokens.
    var process: Process { Process(id: self) }

    struct Process {
        let id: AudioObjectID

        var processBundleID: String { id.readString(property: kAudioProcessPropertyBundleID) }
        
        var pid: Int32 { id.read(property: kAudioProcessPropertyPID) }
    }
    
    var device: Device { Device(id: self) }
    
    struct Device {
        let id: AudioObjectID
        
        var uid: String { id.readString(property: kAudioDevicePropertyDeviceUID) }
    }
}

