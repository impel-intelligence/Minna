//
//  MinnaApp.swift
//  Minna
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftUI
import SwiftData
import SentrySwift
import ModelManager
import ModernSettingsWindow

#if SPARKLE
import Sparkle
#endif

@main
struct MinnaApp: App {
    // MARK: Databases
    @State var irisDBController: IrisDBController = IrisDBController(modelContainer: FrontendDatabase.shared.modelContainer)
    @State var frontendDatabase: FrontendDatabase = FrontendDatabase.shared
        
    @State var standardFileImporterPresented: Bool = false
        
    #if SPARKLE
    private let updaterController: SPUStandardUpdaterController
    #endif
    
    init() {
        #if SPARKLE
        // Don't start the sparkle updater under XCTest. Unit tests on CI will fail since sparkle opens a popup asking when to update which hangs the process.
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        updaterController = SPUStandardUpdaterController(startingUpdater: !isRunningTests, updaterDelegate: nil, userDriverDelegate: nil)
        #endif
        
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
            SidebarCommands()

            CommandGroup(replacing: .newItem) {
                AddItemMenuButtons(presentLocalFilePicker: $standardFileImporterPresented)
                    .standardFileImporter(
                        presented: $standardFileImporterPresented,
                        selectedFolder: nil,
                        modelContext: frontendDatabase.modelContainer.mainContext,
                        irisContext: irisDBController.mainContext,
                        database: frontendDatabase
                    )
            }
            #if SPARKLE
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            #endif
        }
        .modelContainer(frontendDatabase.modelContainer)
        .database(frontendDatabase)
        .irisContext(irisDBController.mainContext)

        WindowGroup(id: FileWindow.windowID, for: OpenFileAction.self) { $parameters in
            if let parameters = parameters {
                FileWindow(parameters: parameters, context: frontendDatabase.modelContainer.mainContext)
                    .modelContainer(frontendDatabase.modelContainer)
                    .irisContext(irisDBController.mainContext)
            }
        }

        ModernSettings {
            SettingsController()
        }
        .modelContainer(frontendDatabase.modelContainer)
        .irisContext(irisDBController.mainContext)
    }
}
