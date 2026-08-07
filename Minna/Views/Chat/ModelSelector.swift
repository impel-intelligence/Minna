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

    @Binding var providerDatabase: OrderedDictionary<ConfiguredProvider, [any Model]>
    @Binding var selectedModel: (any Model)?
    let didSelect: ((any Model), ConfiguredProvider) -> ()

    var body: some View {
        VStack {
            header
            List {
                ForEach(Array(providerDatabase.keys)) { provider in
                    Section(provider.name) {
                        ForEach(providerDatabase[provider] ?? [], id: \.id) { model in
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
    func cellFor(model: any Model, provider: ConfiguredProvider) -> some View {
        Button {
            preferredModel = model.id
            didSelect(model, provider)
        } label: {
            HStack {
                Image(systemSymbol: .checkmark)
                    .fontWeight(.semibold)
                    .symbolEffect(.bounce, value: selectedModel?.id == model.id)
                    .opacity(selectedModel?.id == model.id ? 1 : 0)
                    .accessibilityLabel("Model Selected", isEnabled: selectedModel?.id == model.id)
                
                ModelName(model: model)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selectedModel: (any Model)?
    @Previewable @State var selectedProvider: ConfiguredProvider?

    @Previewable @State var providerDatabase: OrderedDictionary<ConfiguredProvider, [any Model]> = [
        ConfiguredProvider(name: "Apple Intelligence", providerID: "apple"): [
            SimpleModel(id: "foundation", displayName: "Apple Foundation", provider: AppleProvider.self)
        ]
    ]
    
    ModelSelector(providerDatabase: $providerDatabase, selectedModel: $selectedModel) { _, _ in }
}
 
