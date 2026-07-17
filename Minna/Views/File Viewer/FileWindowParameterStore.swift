//
//  FileWindowParameterStore.swift
//  Minna
//
//  Created by Taylor Lineman on 7/17/26.
//

import Foundation
import SwiftData

final class FileWindowParameterStore {
    static let parametersChanged: Notification.Name = Notification.Name("FileWindowParameterStore.parametersChanged")
    
    static let shared: FileWindowParameterStore = FileWindowParameterStore()
    
    private(set) var parameterStore: [OpenFileAction: OpenFileParameters] = [:]
    
    private init() { }
    
    func setParameters(for action: OpenFileAction, to parameters: OpenFileParameters) {
        self.parameterStore[action] = parameters
        NotificationCenter.default.post(name: FileWindowParameterStore.parametersChanged, object: action)
    }
    
    func consumeParameters(for action: OpenFileAction) -> OpenFileParameters? {
        if let parameters = parameterStore[action] {
            parameterStore.removeValue(forKey: action)
            return parameters
        }
        
        return nil
    }
}

struct OpenFileParameters: Codable, Hashable {
    let excertps: [Int]
    
    init(excertps: [Int]) {
        self.excertps = excertps
    }
}

struct OpenFileAction: Identifiable, Codable, Hashable {
    let id: PersistentIdentifier
    
    init(id: PersistentIdentifier,) {
        self.id = id
    }
}
