//
//  IntroVideoView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import SwiftUI

struct IntroVideoView: View {
    @Environment(OnboardingNavigationRouter.self) var onboardingRouter
    
    let url = Bundle.main.url(forResource: "intro", withExtension: "mp4")
    
    @State var showVideo: Bool = false

    var body: some View {
        HStack {
            if let url {
                EndAnnouncingVideoPlayer(url: url) {
                    onboardingRouter.introFinished()
                } doneLoading: {
                    showVideo = true
                }
                .opacity(showVideo ? 1 : 0)
                .animation(.default, value: showVideo)
            } else {
                EmptyView()
                    .onAppear {
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
    .frame(width: 700, height: 450)
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
