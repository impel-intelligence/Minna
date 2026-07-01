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
}

struct ModelsSettingsView: View {
    @Query var providers: [ConfiguredProvider]
    @Query var models: [ChatModel]

    private var onDeviceModels: [ChatModel] {
        models.filter { $0.location == .device }
    }

    private var cloudModels: [ChatModel] {
        models.filter { $0.location == .cloud }
    }
    
    @State var providerWrapper: ProviderWrapper?
    
    var body: some View {
        Form {
            Section("Local Models") {
                NavigationLink("Install New Models") {
                    InstallModelsView()
                }
            }
            
            Section("Configured Providers") {
                ForEach(providers) { provider in
                    if let classedProvider = ProviderFactory.make(id: provider.providerID) {
                        HStack {
                            Image(classedProvider.image)
                                .resizable()
                                .frame(width: 15, height: 15)
                            Text(classedProvider.marketingName)
                        }
                    } else {
                        Text("Invalid Provider: \(provider.providerID)")
                    }
                }
            }
            
            Section("Add a new provider") {
                Button {
                    providerWrapper = ProviderWrapper(provider: AnthropicProvider.self)
                } label: {
                    HStack {
                        Image(AnthropicProvider.image)
                            .resizable()
                            .frame(width: 15, height: 15)
                        Text(AnthropicProvider.marketingName)
                    }
                }
                .clipShape(.rect)
                .buttonStyle(NavigationLinkButtonStyle())
                .accessibilityLabel("Add Claude (Anthropic) as a model provider.")
            }

        }
        .formStyle(.grouped)
        .navigationTitle("Models")
        .sheet(item: $providerWrapper) { wrapper in
            AddProviderForm(wrapper: wrapper)
        }
    }
}

#Preview {
    NavigationStack {
        ModelsSettingsView()
    }
}
