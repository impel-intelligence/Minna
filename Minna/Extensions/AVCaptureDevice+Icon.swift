//
//  AVCaptureDevice+Icon.swift
//  Minna
//
//  Created by Taylor Lineman on 9/9/26.
//

import SFSafeSymbols
import AVFoundation

extension AVCaptureDevice {
    var icon: SFSymbol {
        if modelID == "iPhone Mic" {
            return .iphone
        } else if modelID == "Digital Mic" {
            return .macbook
        } else if localizedName.contains("AirPods") {
            if localizedName.hasSuffix("Max") {
                return .airpodsMax
            }
            
            return .airpods
        }
        
        return .microphone
    }
}
