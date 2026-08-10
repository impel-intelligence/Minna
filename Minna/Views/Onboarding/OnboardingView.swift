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
        case overview
        case providers
    }

    @State var onboardingPage: OnboardingPage = .overview
    
    var body: some View {
        VStack {
            switch onboardingPage {
            case .overview:
                FeatureOverview {
                    withAnimation {
                        onboardingPage = .providers
                    }
                }
            case .providers:
                VStack {
                    
                }
            }
        }
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
    }
}

#Preview {
    OnboardingView()
}
