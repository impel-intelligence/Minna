//
//  CompositionConfig.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/6/26.
//

import CoreAudio

/// Structure that models a `CFDictionary` for  `kAudioAggregateDevicePropertyComposition`
public struct CompositionConfig: Equatable, Hashable, Sendable {
    struct TapEntry: Equatable, Hashable, Sendable {
        let uid: String
        let driftCompensation: Bool
        
        var dictionary: CFDictionary {
            [
                kAudioSubTapUIDKey: uid,
                kAudioSubTapDriftCompensationKey: driftCompensation
            ] as CFDictionary
        }
    }
    
    let name: String
    let uid: String
//    let mainSubDeviceUID: String?
    let subDeviceUIDs: [String]
    let tapUIDs: [TapEntry]
    var isPrivate: Bool = true
    var autoStart: Bool
    var isStacked: Bool

    var composition: CFDictionary {
        [
            kAudioAggregateDeviceNameKey: name,
            kAudioAggregateDeviceUIDKey: uid,
//            kAudioAggregateDeviceMainSubDeviceKey: mainSubDeviceUID ?? "",
            kAudioAggregateDeviceSubDeviceListKey: subDeviceUIDs.map({ [ kAudioSubDeviceUIDKey: $0 ] }),
            kAudioAggregateDeviceTapListKey: tapUIDs.map(\.dictionary),
            kAudioAggregateDeviceTapAutoStartKey: autoStart,
            kAudioAggregateDeviceIsPrivateKey: isPrivate,
            kAudioAggregateDeviceIsStackedKey: isStacked
        ] as CFDictionary
    }
}
