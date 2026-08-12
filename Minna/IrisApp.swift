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
    @State var sentryCrashID: SentryId = .empty
    
    @State var standardFileImporterPresented: Bool = false
    
    @AppStorage("onboarding") var isOnboarding: Bool = true
        
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
        LoggingSystem.bootstrap(LoggingBackend.init)
        #endif

        frontendDatabase = FrontendDatabase.shared
        irisDBContext = IrisContext(modelContainer: FrontendDatabase.shared.modelContainer)

        let POSTHOG_PROJECT_TOKEN = "phc_nZHzNbtLBtLumJz9Yi6MvnzK2GDcMpt3MLCv6vDJxcSb"
        let POSTHOG_HOST = "https://us.i.posthog.com"

        let config = PostHogConfig(projectToken: POSTHOG_PROJECT_TOKEN, host: POSTHOG_HOST)
        PostHogSDK.shared.setup(config)

        SentrySDK.start { [self] options in
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
            
            options.onLastRunStatusDetermined = { [self] status, crashEvent in
                if status == .didCrash, let event = crashEvent {
                    Log.logger.error("App crashed last run", metadata: ["sentry_id": "\(event.eventId.sentryIdString)"])
                    
                    self.sentryCrashID = event.eventId
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup("Dashboard", id: "dashboard") {
            if isOnboarding {
                OnboardingView()
                    .modelContainer(frontendDatabase.modelContainer)
                    .database(frontendDatabase)
                    .irisContext(irisDBContext)
                    .environment(modelManager)
                    .frame(width: 900, height: 500)
                    .windowResizeBehavior(.disabled)
            } else {
                NavigationCore()
                    .modelContainer(frontendDatabase.modelContainer)
                    .database(frontendDatabase)
                    .irisContext(irisDBContext)
                    .environment(modelManager)
            }
        }
        .defaultSize(width: 900, height: 500)
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
            
            CommandGroup(after: .appInfo) {
                #if SPARKLE
                CheckForUpdatesView(updater: updaterController.updater)
                #endif
                Button {
                    openWindow(id: "bugReport")
                } label: {
                    Label("Send Feedback", systemSymbol: .megaphone)
                }
            }
            
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
                    .database(frontendDatabase)
                    .irisContext(irisDBContext)
                    .environment(modelManager)
            }
        }
        
        WindowGroup(id: "bugReport") {
            SentryReporter(eventId: sentryCrashID)
        }
        .onChange(of: sentryCrashID, initial: true) { _, _ in
            if sentryCrashID != .empty {
                openWindow(id: "bugReport")
            }
        }
        
        ModernSettings {
            SettingsController()
                .modelContainer(frontendDatabase.modelContainer)
                .irisContext(irisDBContext)
        }
    }
}
