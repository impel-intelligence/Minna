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
    @State var standardFileImporterPresented: Bool = false
    
    var body: some Scene {
        WindowGroup {
            NavigationCore()
                .environment(AlertCenter.shared)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                AddItemMenuButtons(presentLocalFilePicker: $standardFileImporterPresented)
                    .standardFileImporter(presented: $standardFileImporterPresented, selectedFolder: nil, modelContext: Database.shared.modelContainer.mainContext)
            }
        }
        .modelContainer(Database.shared.modelContainer)
    }
}
