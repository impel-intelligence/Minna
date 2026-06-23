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
    // MARK: Databases
    @State var irisDBController: IrisDBController
    @State var frontendDatabase: FrontendDatabase
    
    @State var searchController: SearchController
    
    @State var standardFileImporterPresented: Bool = false
    
    init() {
        self.frontendDatabase = FrontendDatabase.shared
        self.irisDBController = IrisDBController()

        self.searchController = SearchController()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationCore()
                .environment(AlertCenter.shared)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                AddItemMenuButtons(presentLocalFilePicker: $standardFileImporterPresented)
                    .standardFileImporter(
                        presented: $standardFileImporterPresented,
                        selectedFolder: nil,
                        modelContext: frontendDatabase.modelContainer.mainContext,
                        irisContext: irisDBController.mainContext
                    )
            }
        }
        .modelContainer(frontendDatabase.modelContainer)
        .irisContext(irisDBController.mainContext)
    }
}
