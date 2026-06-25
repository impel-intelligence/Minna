//
//  IrisApp.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftUI
import SwiftData
import SentrySwift
import Sparkle

@main
struct IrisApp: App {
    // MARK: Databases
    @State var irisDBController: IrisDBController
    @State var frontendDatabase: FrontendDatabase
    
    @State var searchController: SearchController
    
    @State var standardFileImporterPresented: Bool = false
    
    private let updaterController: SPUStandardUpdaterController

    init() {
        self.frontendDatabase = FrontendDatabase.shared
        self.irisDBController = IrisDBController(modelContainer: FrontendDatabase.shared.modelContainer)

        self.searchController = SearchController()

        // Don't start the sparkle updater under XCTest. Unit tests on CI will fail since sparkle opens a popup asking when to update which hangs the process.
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        updaterController = SPUStandardUpdaterController(startingUpdater: !isRunningTests, updaterDelegate: nil, userDriverDelegate: nil)
        
        SentrySDK.start { options in
            options.dsn = "https://b74c5dc356db0cda226438d09eb33a87@o4511615856607232.ingest.us.sentry.io/4511615959105537"
            options.sendDefaultPii = false
            options.enableUncaughtNSExceptionReporting = true
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationCore()
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
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        .modelContainer(frontendDatabase.modelContainer)
        .irisContext(irisDBController.mainContext)
    }
}
