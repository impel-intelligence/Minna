//
//  DeviceFinder.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/9/26.
//

import AVFoundation

public struct DeviceFinder {
    public static func defaultMicrophone() throws -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .microphone, .external
        ]
        
        return AVCaptureDevice.default(for: .audio)
    }
    
    public static func microphones() throws -> [AVCaptureDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .microphone, .external
        ]

        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .audio,
            position: .unspecified
        )

        let microphones = session.devices
        return microphones
    }
}
