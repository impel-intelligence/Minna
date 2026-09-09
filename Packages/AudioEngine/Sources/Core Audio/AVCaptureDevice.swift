//
//  AVCaptureDevice.swift
//  AudioEngine
//
//  Created by Taylor Lineman on 9/9/26.
//

import AVFoundation
import CoreAudio

public extension AVCaptureDevice {
    var audioObjectID: AudioObjectID? {
        get throws {
            let ids = try AudioObjectID.devicesList()
            return ids.first { id in
                (try? id.device.uid) == self.uniqueID
            }
        }
    }
}
