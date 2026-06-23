//
//  IrisApp.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftUI
import SwiftData
import Sentry

@main
struct IrisApp: App {
    // MARK: Databases
    @State var irisDBController: IrisDBController
    @State var frontendDatabase: FrontendDatabase
    
    @State var searchController: SearchController
    
    @State var standardFileImporterPresented: Bool = false
    
    init() {
        self.frontendDatabase = FrontendDatabase.shared
        self.irisDBController = IrisDBController(modelContainer: FrontendDatabase.shared.modelContainer)

        self.searchController = SearchController()
        
        SentrySDK.start { options in
            options.dsn = "https://b74c5dc356db0cda226438d09eb33a87@o4511615856607232.ingest.us.sentry.io/4511615959105537"
            options.sendDefaultPii = false
            options.enableUncaughtNSExceptionReporting = true
        }
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
