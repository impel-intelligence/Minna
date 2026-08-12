//
//  OnboardingFinishedView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import SwiftUI
import SFSafeSymbols

struct OnboardingFinishedView: View {
    @AppStorage("onboarding") var isOnboarding: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            Image(systemSymbol: .partyPopper)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75, height: 75)
                .accessibilityHidden(true)

            Text("Minna is ready to go!")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Thank you for joining the Minna Beta! You can always contact support at [support@tryminna.com](mailto:support@tryminna.com) if you have any issues!")
                .frame(width: 350)
            
            Button {
                isOnboarding = false
            } label: {
                Text("Get Started")
            }
            .controlSize(.extraLarge)
            .buttonStyle(.borderedProminent)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    OnboardingFinishedView()
}
