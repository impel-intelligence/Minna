//
//  IntroVideoView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import SwiftUI
import SFSafeSymbols

struct IntroVideoView: View {
    @Environment(OnboardingNavigationRouter.self) var onboardingRouter
    
    let url = Bundle.main.url(forResource: "intro", withExtension: "mp4")
    
    @State var showVideo: Bool = false

    var body: some View {
        HStack {
            if let url {
                EndAnnouncingVideoPlayer(url: url) {
                    TelemetryWrapper.shared.onboardingStage(stage: .intro)
                    onboardingRouter.introFinished()
                } doneLoading: {
                    showVideo = true
                } failedToLoad: {
                    TelemetryWrapper.shared.onboardingStage(stage: .intro)
                    onboardingRouter.introFinished()
                }
                .opacity(showVideo ? 1 : 0)
                .animation(.default, value: showVideo)
            } else {
                ContentUnavailableView("Could not load intro video", systemSymbol: .videoSlash)
                    .task {
                        TelemetryWrapper.shared.onboardingStage(stage: .intro)
                        onboardingRouter.introFinished()
                    }
            }
        }
        .ignoresSafeArea()
        .toolbarVisibility(.hidden, for: .windowToolbar)
    }
}

#Preview {
    IntroVideoView()
        .frame(width: 900, height: 500)
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MinnaLogo()

            }
            .sharedBackgroundVisibility(.hidden)
        }
        .environment(ModelManager())

}
