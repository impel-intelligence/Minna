//
//  ModelSelector.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import OrderedCollections
import ModernSettingsWindow
import DatabaseSchema
import ModelManager
import SFSafeSymbols

struct ModelSelector: View {
    @Environment(\.openModernSettings) var openSettings
    
    @AppStorage(AppStorageKeys.preferredModel) var preferredModel: String = ""

    @Binding var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]>
    @Binding var selectedModel: Model?
    @Binding var selectedProvider: ConfiguredProvider?

    var body: some View {
        VStack {
            header
            List {
                ForEach(Array(providerDatabase.keys)) { provider in
                    Section(provider.name) {
                        ForEach(providerDatabase[provider] ?? []) { model in
                            cellFor(model: model, provider: provider)
                        }
                    }
                    .listRowSeparator(.hidden, edges: .all)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .frame(width: 350, height: 450)
    }
    
    var header: some View {
        HStack {
            Text("Available Models")
                .font(.title3)
                .bold()
                .lineLimit(1)
            HStack(alignment: .center) {
                Text("\(providerDatabase.flatMap({$0.value}).count)")
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 10, weight: .regular, design: .default))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.pillBackground)
            .clipShape(.rect(cornerRadius: 4))
            Spacer()
            Button {
                openSettings()
            } label: {
                Label("Get More", systemSymbol: .plus)
            }
        }
        .padding(.top, 10)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func cellFor(model: Model, provider: ConfiguredProvider) -> some View {
        Button {
            selectedModel = model
            selectedProvider = provider
            preferredModel = model.id
        } label: {
            HStack {
                Image(systemSymbol: .checkmark)
                    .fontWeight(.semibold)
                    .symbolEffect(.bounce, value: selectedModel == model)
                    .opacity(selectedModel == model ? 1 : 0)
                    .accessibilityLabel("Model Selected", isEnabled: selectedModel == model)
                
                ModelName(model: model)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selectedModel: Model?
    @Previewable @State var selectedProvider: ConfiguredProvider?
    
    @Previewable @State var providerDatabase: OrderedDictionary<ConfiguredProvider, [Model]> = [
        ConfiguredProvider(name: "Apple Intelligence", providerID: "apple"): [
            Model(id: "foundation", displayName: "Apple Foundation", provider: AppleProvider.self)
        ]
    ]
    
    ModelSelector(providerDatabase: $providerDatabase, selectedModel: $selectedModel, selectedProvider: $selectedProvider)
}
