//
//  ModelsSettingsView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-07-01.
//

import SwiftUI
import SwiftData
import DatabaseSchema
import SFSafeSymbols
import ModelManager

struct ProviderWrapper: Identifiable {
    var id: String { provider.id }

    /// The provider being configured. It owns the description of the fields the
    /// form should render (via `provider.fields`) and knows how to build itself
    /// from the collected input (via `provider.make(from:)`).
    let provider: any ModelProvider.Type
    
    let existingConfiguration: ConfiguredProvider?
}

struct ModelsSettingsView: View {
    @Query var providers: [ConfiguredProvider]

    @State var providerWrapper: ProviderWrapper?
    
    var body: some View {
        Form {
//            Section("Local Models") {
//                NavigationLink("Install New Models") {
//                    InstallModelsView()
//                }
//            }
            
            Section("Configured Providers") {
                ForEach(providers) { configuration in
                    if let classedProvider = ProviderFactory.makeType(id: configuration.providerID) {
                        if classedProvider.editable {
                            Button {
                                providerWrapper = ProviderWrapper(provider: classedProvider, existingConfiguration: configuration)
                            } label: {
                                labelFor(provider: classedProvider, configuration: configuration)
                            }
                            .contentShape(.rect)
                            .buttonStyle(NavigationLinkButtonStyle())
                            .accessibilityLabel("Edit \(configuration.name)")
                        } else {
                            labelFor(provider: classedProvider, configuration: configuration)
                        }
                    } else {
                        Text("Invalid Provider: \(configuration.providerID)")
                    }
                }
            }
            
            Section("Add a new provider") {
                buttonFor(provider: AnthropicProvider.self)
                buttonFor(provider: GeminiProvider.self)
                buttonFor(provider: OllamaProvider.self)
                buttonFor(provider: OpenAIProvider.self)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Models")
        .sheet(item: $providerWrapper) { wrapper in
            ProviderConfigurationForm(wrapper: wrapper)
        }
    }
    
    @ViewBuilder
    func buttonFor<Provider: ModelProvider & AssetProvider>(provider: Provider.Type) -> some View {
        Button {
            providerWrapper = ProviderWrapper(provider: provider, existingConfiguration: nil)
        } label: {
            HStack {
                Image(provider.image)
                    .resizable()
                    .frame(width: 15, height: 15)
                Text(provider.marketingName)
            }
        }
        .contentShape(.rect)
        .buttonStyle(NavigationLinkButtonStyle())
        .accessibilityLabel("Add \(provider.marketingName) as a model provider.")
    }
    
    @ViewBuilder
    func labelFor(provider: any ModelProvider.Type, configuration: ConfiguredProvider) -> some View {
        if let assetProvider = provider as? (any AssetProvider.Type) {
            HStack {
                Image(assetProvider.image)
                    .resizable()
                    .frame(width: 15, height: 15)
                    .accessibilityLabel("\(assetProvider.marketingName) Logo")
                
                // If the user set a custom name for this provider, show the name of the provider as a subtitle.
                if configuration.name != assetProvider.marketingName {
                    VStack(alignment: .leading) {
                        Text(configuration.name)
                        Text(assetProvider.marketingName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(configuration.name)
                }
            }
        } else {
            Text(configuration.name)
        }
    }
}

#Preview {
    NavigationStack {
        ModelsSettingsView()
    }
}
