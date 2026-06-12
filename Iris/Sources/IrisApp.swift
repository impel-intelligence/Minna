//
//  IrisApp.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftUI
import SwiftData

@main
struct IrisApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationCore()
        }
        .modelContainer(Database.shared.modelContainer)
    }
}
