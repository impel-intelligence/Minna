//
//  Untitled.swift
//  FileMonitor
//
//  Created by Taylor Lineman on 8/26/26.
//

import Dispatch
import Foundation

// https://stackoverflow.com/a/43478015/14886210
class FileMonitor {
    private var dispatchQueue: DispatchQueue
    
    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol
    let eventMask: DispatchSource.FileSystemEvent
    
    init(URL: URL,
         dispatchQueue: DispatchQueue = DispatchQueue(label: "FileMonitor"),
         eventMask: DispatchSource.FileSystemEvent = [.all],
         block: @escaping ()->Void
    ) {
        self.dispatchQueue = dispatchQueue
        self.eventMask = eventMask
        fileDescriptor = open(URL.path, O_EVTONLY)
        
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: eventMask, queue: dispatchQueue)

        source.setEventHandler {
            block()
        }

        source.resume()
    }
    
    
    deinit {
        self.source.cancel()
        close(fileDescriptor)
    }
    
}
