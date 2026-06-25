//
//  AlertCenter.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

import SwiftUI


//@Observable
//final class AlertCenter {
//    static let shared: AlertCenter = AlertCenter()
//    
//    private(set) var notifications: [UserNotification] = []
//    
//    private init() { }
//    
//    func post(_ notification: UserNotification) {
//        notifications.insert(notification, at: 0)
//    }
//
//    func dismiss(_ id: UserNotification.ID) {
//        notifications.removeAll { $0.id == id }
//    }
//}
//
//extension EnvironmentValues {
//    @Entry var alertCenter: AlertCenter = AlertCenter.shared
//}
//
//
//extension View {
//    func alertCenter(_ alertCenter: AlertCenter) -> some View {
//        environment(\.alertCenter, alertCenter)
//    }
//}
