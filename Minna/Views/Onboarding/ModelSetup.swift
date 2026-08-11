//
//  ProvidersView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/10/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-10

import SwiftUI
import ModelManager
import DatabaseSchema
import SFSafeSymbols
import ModelCDN

struct ModelSetupView: View {
    var body: some View {
        NavigationStack {
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
                    NavigationLink("With my own AI Providers") {
                        ProviderSetupView()
                    }
                    .controlSize(.extraLarge)
                    
                    NavigationLink("Completely On Device") {
                        OnDeviceSetup()
                    }
                    .controlSize(.extraLarge)
                    .buttonStyle(.borderedProminent)

                }
                .padding()
            }
        }
    }
}

#Preview {
    OnDeviceSetup()
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
