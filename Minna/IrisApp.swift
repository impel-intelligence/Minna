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
import Logging
import SFSafeSymbols
import PostHog

#if canImport(Darwin)
import LoggingOSLog
#endif

#if SPARKLE
import Sparkle
#endif

@main
struct MinnaApp: App {
    @Environment(\.openWindow) var openWindow
    
    // MARK: Databases
    @State var irisDBContext: IrisContext
    @State var frontendDatabase: FrontendDatabase
    @State var modelManager: ModelManager = ModelManager()
    
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
        
        #if canImport(Darwin)
        // TODO: Find an OSLog implementation that handles the Swift-log error types
//        LoggingSystem.bootstrap(LoggingOSLog.init)
        #endif

        let POSTHOG_PROJECT_TOKEN = "phc_nZHzNbtLBtLumJz9Yi6MvnzK2GDcMpt3MLCv6vDJxcSb"
        let POSTHOG_HOST = "https://us.i.posthog.com"

        let config = PostHogConfig(projectToken: POSTHOG_PROJECT_TOKEN, host: POSTHOG_HOST)
        PostHogSDK.shared.setup(config)

        SentrySDK.start { options in
            options.dsn = "https://b74c5dc356db0cda226438d09eb33a87@o4511615856607232.ingest.us.sentry.io/4511615959105537"
            options.sendDefaultPii = false
            options.enableUncaughtNSExceptionReporting = true
                        
            #if SPARKLE
            options.dist = "sparkle"
            #if DEBUG
            options.environment = "sparkle_debug"
            #else
            options.environment = "sparkle_release"
            #endif // DEBUG
            #else
            options.dist = "app_store"
            #if DEBUG
            options.environment = "app_store_debug"
            #else
            options.environment = "app_store_release"
            #endif // DEBUG
            #endif // SPARKLE
        }
        
        frontendDatabase = FrontendDatabase.shared
        irisDBContext = IrisContext(modelContainer: FrontendDatabase.shared.modelContainer)
    }
    
    var body: some Scene {
        WindowGroup("Dashboard", id: "dashboard") {
            NavigationCore()
                .modelContainer(frontendDatabase.modelContainer)
                .database(frontendDatabase)
                .irisContext(irisDBContext)
                .environment(modelManager)
        }
        .commands {
            SidebarCommands()

            CommandGroup(replacing: .newItem) {
                AddItemMenuButtons(presentLocalFilePicker: $standardFileImporterPresented)
                    .standardFileImporter(
                        presented: $standardFileImporterPresented,
                        selectedFolder: nil,
                        modelContext: frontendDatabase.modelContainer.mainContext,
                        irisContext: irisDBContext,
                        database: frontendDatabase
                    )
            }
            #if SPARKLE
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            #endif
            
            CommandGroup(after: .singleWindowList) {
                Button("Dashboard") {
                    openWindow(id: "dashboard")
                }
            }
        }

        WindowGroup(id: PreviewWindow.windowID, for: OpenFileAction.self) { $parameters in
            if let parameters = parameters {
                PreviewWindow(parameters: parameters, context: frontendDatabase.modelContainer.mainContext)
                    .modelContainer(frontendDatabase.modelContainer)
                    .irisContext(irisDBContext)
            }
        }
        
        ModernSettings {
            SettingsController()
                .modelContainer(frontendDatabase.modelContainer)
                .irisContext(irisDBContext)
        }
    }
}
