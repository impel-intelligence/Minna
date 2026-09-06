//
//  AudioProcess.swift
//  AudioEngine
//
//  Originally from Apple: https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps
//  Edited by Taylor Lineman on 9/6/26.
//

import CoreAudio
import AppKit

protocol AudioProcessDelegate {
    func processStopped(id: AudioObjectID)
}

class AudioProcess: Identifiable, Hashable {
    let dispatchQueue: DispatchQueue

    let id: AudioObjectID
    let name: String
    
    var isRunning = false
    var delegate: AudioProcessDelegate?
    
    var isRunningAddress = CoreAudio.getPropertyAddress(selector: kAudioProcessPropertyIsRunning)
    var isRunningToken: AudioObjectPropertyListenerBlock?
    
    init(id: AudioObjectID, queue: DispatchQueue = .main) {
        self.id = id
        self.dispatchQueue = queue
        
        self.name = AudioProcess.processName(pid: id.process.pid)
        self.updateIsRunning()
        
        registerListeners()
    }
    
    deinit {
        unregisterListeners()
    }
    
    static func == (lhs: AudioProcess, rhs: AudioProcess) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func registerListeners() {
        let isRunningChanged: AudioObjectPropertyListenerBlock = { inNumberAddresses, inAddresses in
            for index in 0..<inNumberAddresses {
                let address = inAddresses[Int(index)]
                switch address.mSelector {
                case kAudioProcessPropertyIsRunning:
                    self.updateIsRunning()
                default:
                    break
                }
            }
        }
        
        AudioObjectAddPropertyListenerBlock(id, &isRunningAddress, DispatchQueue.main, isRunningChanged)
        isRunningToken = isRunningChanged
    }
    
    func unregisterListeners() {
        guard let token = isRunningToken else { return }

        AudioObjectRemovePropertyListenerBlock(id, &isRunningAddress, DispatchQueue.main, token)
        isRunningToken = nil
    }
    
    func updateIsRunning() {
        // Get the `isRunning` property of the process object.
        var propertySize = UInt32(MemoryLayout<UInt32>.stride)
        var running: UInt32 = 0
        AudioObjectGetPropertyData(self.id, &isRunningAddress, 0, nil, &propertySize, &running)
        
        let oldState = self.isRunning
        self.isRunning = running != 0
        
        // Check whether the process stopped running.
        if oldState && !isRunning {
            delegate?.processStopped(id: self.id)
        }
    }
}

extension AudioProcess {
    /// Retrieve the name of the process running at `pid`. First attempt retrieval from AppKit, then from `sysctl`
    /// 
    /// - Parameter pid: The pid to find the process name for.
    /// - Returns: The name of the process running at `pid`.
    private static func processName(pid: Int32) -> String {
        // Try to get the localized process name from the app using `NSWorkspace`.
        for app in NSWorkspace.shared.runningApplications where app.processIdentifier == pid {
            return app.localizedName ?? ""
        }
    
        // Otherwise use `sysctl` to obtain the process name.
        var result: String = ""
        var info = kinfo_proc()
        var len = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
       
        if (sysctl(&mib, 4, &info, &len, nil, 0) != -1) && len > 0 {
            withUnsafePointer(to: info.kp_proc.p_comm) {
                $0.withMemoryRebound(to: UInt8.self, capacity: len) {
                    result = String(cString: $0)
                }
            }
        }
        
        return result
    }
}
