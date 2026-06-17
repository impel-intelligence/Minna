//
//  UserNotification.swift
//  Iris
//
//  Created by Taylor Lineman on 6/17/26.
//

import Foundation
import SwiftUI

struct UserNotification: Identifiable {    
    struct ActionOption: Identifiable {
        let id: UUID = UUID()
        
        let title: String
        let action: @Sendable () -> Void
        let role: ButtonRole?
        
        init(title: String, role: ButtonRole? = nil, action: @Sendable @escaping () -> Void) {
            self.title = title
            self.role = role
            self.action = action
        }
    }
    
    let id: UUID = UUID()
    
    let title: String
    let message: String
    let creationDate: Date

    let actions: [ActionOption]
    

    init(title: String, message: String, creationDate: Date = .now, actions: [ActionOption]) {
        self.title = title
        self.message = message
        self.actions = actions
        self.creationDate = creationDate
    }
}
