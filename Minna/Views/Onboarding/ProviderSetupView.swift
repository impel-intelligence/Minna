//
//  ProviderSetupView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//


//
//  ProviderSetupView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//  Edited by Claude Opus 5 (Anthropic) on 2026-08-11
//

import SwiftUI
import SwiftData
import ModelManager
import DatabaseSchema
import SFSafeSymbols
import ModelCDN

struct ProviderSetupView: View {
    private typealias Provider = (ModelProvider & AssetProvider)
    
    @AppStorage("onboarding") var isOnboarding: Bool = true

    @Environment(\.modelContext) private var modelContext
    @State var providerWrapper: ProviderWrapper?
    @Query var providers: [ConfiguredProvider]
    @State var hasConfiguredAProvider: Bool = false
    
    private let supportedProviders: [Provider.Type] = [
        AnthropicProvider.self,
        OpenAIProvider.self,
        OllamaProvider.self,
        GeminiProvider.self
    ]

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Add an AI Provider")
                .font(.title)
                .fontWeight(.semibold)
            Text("You can set up as many AI providers as you want. You can also set up multiple instances of the same provider if you have multiple accounts.")
                .frame(width: 300)

            HStack(spacing: 20) {
                // Looping over indices here since type checking can't handle the odd Provider type.
                ForEach(supportedProviders.enumerated(), id: \.offset) { (offset, index) in
                    buttonFor(provider: index)
                }
            }
            .padding(.vertical)
            
            Button("Get Started") {
                isOnboarding = false
            }
            .controlSize(.extraLarge)
            .buttonStyle(.borderedProminent)
            .disabled(!hasConfiguredAProvider)
        }
        .multilineTextAlignment(.center)
        .sheet(item: $providerWrapper) { wrapper in
            ProviderConfigurationForm(wrapper: wrapper)
        }
        .onChange(of: providers, initial: true) { _, newValue in
            // Check if we have configured one of the providers this view supports.
            if newValue.contains(where: { provider in
                return supportedProviders.contains(where: { supported in
                    return supported.id == provider.providerID
                })
            }) {
                hasConfiguredAProvider = true
            }
        }
    }

    @ViewBuilder
    private func buttonFor(provider: Provider.Type) -> some View {
        Button {
            providerWrapper = ProviderWrapper(provider: provider, existingConfiguration: nil)
        } label: {
            VStack {
                Image(provider.image)
                    .resizable()
                    .frame(width: 45, height: 45)
                    .padding(10)
                    .background(provider.background)
                    .clipShape(.rect(cornerRadius: 20))
                    .shadow(radius: 4)
                Text(provider.marketingName)
            }
            .overlay(alignment: .topTrailing) {
                if providers.contains(where: { configuredProvider in
                    configuredProvider.providerID == provider.id
                }) {
                    Image(systemSymbol: .checkmarkCircleFill)
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.green)
                        .accessibilityLabel("Configured")
                        .offset(x: 3, y: -3)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(.rect)
        .accessibilityLabel("Add \(provider.marketingName) as a model provider.")
    }
}

#Preview {
    NavigationStack {
        ProviderSetupView()
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
}
