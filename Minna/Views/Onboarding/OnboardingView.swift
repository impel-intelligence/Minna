// Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-10
//
//  OnboardingView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/10/26.
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

    @State var onboardingPage: OnboardingPage = .intro
    
    var body: some View {
        VStack {
            switch onboardingPage {
            case .intro:
                IntroVideoView {
                    onboardingPage = .overview
                }
            case .overview:
                FeatureOverview {
                    withAnimation {
                        onboardingPage = .models
                    }
                }
            case .models:
                ModelSetupView()
            }
        }
        .frame(width: 700, height: 450)
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
}

#Preview {
    OnboardingView()
}
