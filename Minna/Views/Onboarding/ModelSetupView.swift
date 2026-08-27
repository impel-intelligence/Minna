//
//  ModelSetupView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/10/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-10, 2026-08-11

import SwiftUI
import ModelManager
import DatabaseSchema
import SFSafeSymbols
import ModelCDN

struct ModelSetupView: View {
    @Environment(OnboardingNavigationRouter.self) var onboardingRouter
    @Environment(ModelManager.self) var modelManager
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
                Image(systemSymbol: .cpu)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 75, height: 75)
                Text("Customize your AI experience")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("Minna can be used completely offline or you can connect an AI provider. Connecting a provider will send your chats off-device and will no longer be secured by Minna.")
                    .multilineTextAlignment(.center)
                    .frame(width: 350)
                HStack {
                    Button("With my own AI Providers") {
                        TelemetryWrapper.shared.onboardingStage(stage: .modelQuestionnaire)
                        onboardingRouter.inferenceQuestionnaire(result: .providers, modelManager: modelManager)
                    }
                    .controlSize(.extraLarge)
                    
                    Button("Completely On Device") {
                        TelemetryWrapper.shared.onboardingStage(stage: .modelQuestionnaire)
                        onboardingRouter.inferenceQuestionnaire(result: .onDevice, modelManager: modelManager)
                    }
                    .controlSize(.extraLarge)
                    .buttonStyle(.borderedProminent)

                }
                .padding()
        }
    }
}

#Preview {
    ModelSetupView()
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
