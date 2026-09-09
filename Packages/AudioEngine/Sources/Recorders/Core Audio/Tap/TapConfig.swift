//
//  TapConfig.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

/// Structure that models a `CATapDescription` object.
public struct TapConfig: Hashable, Sendable {
    public enum TapMute: Int, CaseIterable, Sendable {
        case unmuted = 0
        case muted = 1
        case mutedWhenTapped = 2
    }
    
    public enum TapMixdown: Int, CaseIterable, Sendable {
        case mono = 0
        case stereo = 1
        case deviceFormat = 2
    }
    
    public let name: String
    public let processes: Set<AudioObjectID>
    public let isPrivate: Bool
    public let isProcessRestoreEnabled: Bool
    public let mute: TapMute
    public let mixdown: TapMixdown
    public let exclusive: Bool
    public let device: String?
    public let streamIndex: UInt?
        
    var description: CATapDescription {
        // Create a tap description.
        let description = CATapDescription()
        
        // Fill out the description properties with the tap configuration from the UI.
        description.name = name
        description.processes = Array(processes)
        description.isPrivate = isPrivate
        description.muteBehavior = CATapMuteBehavior(rawValue: mute.rawValue) ?? description.muteBehavior
        description.isMixdown = mixdown == .mono || mixdown == .stereo
        description.isMono = mixdown == .mono
        description.isExclusive = exclusive
        description.deviceUID = device
        description.stream = streamIndex
        
        return description
    }
    
    init(name: String, processes: Set<AudioObjectID> = [], isPrivate: Bool = false, isProcessRestoreEnabled: Bool = true, mute: TapMute = TapMute.unmuted, mixdown: TapMixdown = TapMixdown.stereo, exclusive: Bool = false, device: String? = nil, streamIndex: UInt? = nil) {
        self.name = name
        self.processes = processes
        self.isPrivate = isPrivate
        self.isProcessRestoreEnabled = isProcessRestoreEnabled
        self.mute = mute
        self.mixdown = mixdown
        self.exclusive = exclusive
        self.device = device
        self.streamIndex = streamIndex
    }
    
    init(description: CATapDescription) {
        name = description.name
        processes = Set(description.processes)
        isPrivate = description.isPrivate
        isProcessRestoreEnabled = description.isProcessRestoreEnabled
        mute = TapMute(rawValue: description.muteBehavior.rawValue) ?? TapMute.unmuted
        mixdown = description.isMixdown ? (description.isMono ? .mono : .stereo) : .deviceFormat
        exclusive = description.isExclusive
        device = description.deviceUID
        streamIndex = description.stream ?? 0
    }
}
