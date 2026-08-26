//
//  MinnaApp.swift
//  Minna
//
//  Created by Taylor Lineman on 6/11/26.
//  Edited by Claude Opus 5 (Anthropic) on 2026-08-13
//

import SwiftUI
import SwiftData
import SentrySwift
import ModelManager
import ModernSettingsWindow
import Logging
import SFSafeSymbols

#if SPARKLE
import Sparkle
#endif

@Observable
final class SentryBox {
    var sentryCrashID: SentryId = .empty
}

@main
struct MinnaApp: App {
    @Environment(\.openWindow) var openWindow
    
    let sentryErrorBox: SentryBox
    
    // MARK: Databases
    @State var irisDBContext: IrisContext
    @State var frontendDatabase: FrontendDatabase
    @State var modelManager: ModelManager = ModelManager()
    
    @State var standardFileImporterPresented: Bool = false
    
    @AppStorage("onboarding") var isOnboarding: Bool = true
        
    #if SPARKLE
    private let updaterController: SPUStandardUpdaterController
    #endif
    
    init() {
        let sentryBox = SentryBox()
        
        // Crash reporting is opt-in via Config.xcconfig. Builds from a clean checkout have no DSN configured and report nothing.
        if let sentryDSN = BuildConfiguration.sentryDSN {
            SentrySDK.start { options in
                options.dsn = sentryDSN
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

                options.onLastRunStatusDetermined = { status, crashEvent in
                    if status == .didCrash, let event = crashEvent {
                        Log.logger.error("App crashed last run", metadata: ["sentry_id": "\(event.eventId.sentryIdString)"])
                        sentryBox.sentryCrashID = event.eventId
                    }
                }
            }
        }
        
        // Initialize the telemetry wrapper
        let _ = TelemetryWrapper.shared

        #if SPARKLE
        // Don't start the sparkle updater under XCTest. Unit tests on CI will fail since sparkle opens a popup asking when to update which hangs the process.
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        updaterController = SPUStandardUpdaterController(startingUpdater: !isRunningTests, updaterDelegate: nil, userDriverDelegate: nil)
        #endif
        
        #if canImport(Darwin)
        LoggingSystem.bootstrap(LoggingBackend.init)
        #endif

        sentryErrorBox = sentryBox
        frontendDatabase = FrontendDatabase.shared
        irisDBContext = IrisContext(modelContainer: FrontendDatabase.shared.modelContainer)
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
        .defaultLaunchBehavior(.presented)
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
            SentryReporter(eventId: sentryErrorBox.sentryCrashID)
        }
        .defaultLaunchBehavior(.suppressed)
        .onChange(of: sentryErrorBox.sentryCrashID, initial: true) { _, newValue in
            if newValue != .empty {
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
