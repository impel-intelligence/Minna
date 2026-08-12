//
//  OnboardingView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/10/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-11
//

import SwiftUI
import AVFoundation
import AVKit
import SFSafeSymbols

struct OnboardingView: View {
    enum OnboardingPage: Int {
        case intro
        case overview
        case models
    }

    @Environment(ModelManager.self) var modelManager

    @State var onboardingRouter: OnboardingNavigationRouter = OnboardingNavigationRouter()
    @State var onboardingPage: OnboardingPage = .intro
    
    var body: some View {
        NavigationStack(path: $onboardingRouter.path) {
            Group {
                IntroVideoView()
                    .navigationBarBackButtonHidden()
            }
            .environment(onboardingRouter)
            .navigationDestination(for: OnboardingNavigationRouter.OnboardingStage.self) { stage in
                switch stage {
                case .intro:
                    IntroVideoView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: NSColor.windowBackgroundColor))
                        .environment(onboardingRouter)
                case .overview:
                    FeatureOverview()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: NSColor.windowBackgroundColor))
                        .environment(onboardingRouter)
                case .modelQuestionnaire:
                    ModelSetupView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: NSColor.windowBackgroundColor))
                        .environment(onboardingRouter)
                case .providers:
                    ProviderSetupView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: NSColor.windowBackgroundColor))
                        .environment(onboardingRouter)
                case .inferenceModel:
                    if let inferenceIdentifier = modelManager.standardInferenceModel {
                        DownloadingModelView(canSkipDownload: true, modelIdentifier: inferenceIdentifier)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(nsColor: NSColor.windowBackgroundColor))
                            .environment(onboardingRouter)
                    } else {
                        missingRequiredDownload
                    }
                case .embeddingModel:
                    if let embeddingIdentifier = modelManager.standardEmbeddingModel {
                        DownloadingModelView(canSkipDownload: false, modelIdentifier: embeddingIdentifier)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(nsColor: NSColor.windowBackgroundColor))
                            .environment(onboardingRouter)
                    } else {
                        missingRequiredDownload
                    }
                case .finished:
                    OnboardingFinishedView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(nsColor: NSColor.windowBackgroundColor))
                        .environment(onboardingRouter)
                }
            }
        }
        .frame(width: 900, height: 500)
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MinnaLogo()   
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .animation(.default, value: onboardingPage)
    }
    
    var missingRequiredDownload: some View {
        ContentUnavailableView("Unable to fetch required downloads", systemSymbol: .pc, description: Text("Restart Minna to re-fetch the required downloads. If that doesn't work, please contact support."))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: NSColor.windowBackgroundColor))
    }
}

#Preview {
    OnboardingView()
}
