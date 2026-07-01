//
//  AddProviderForm.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import SwiftData
import DatabaseSchema
import SFSafeSymbols
import ModelManager

struct AddProviderForm: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    let wrapper: ProviderWrapper

    /// The user's input, keyed by `ProviderField.key`. This dictionary is the
    /// single source of truth the form collects; on "Add" it is handed straight
    /// to the provider's factory to build a configured provider.
    @State private var values: [String: String] = [:]
    @State private var advancedExpanded: Bool = false
    @State private var errorMessage: String?

    private var fields: [ProviderField] { wrapper.provider.fields }
    private var standardFields: [ProviderField] { fields.filter { !$0.isAdvanced } }
    private var advancedFields: [ProviderField] { fields.filter { $0.isAdvanced } }

    var body: some View {
        Form {

            Section {
                ForEach(standardFields) { field in
                    fieldView(for: field)
                }
            } header: {
                // If this provider has conformance to AssetProvider grab the assets to display.
                if let assetProvider = wrapper.provider as? AssetProvider.Type {
                    HStack(spacing: 15) {
                        Image(assetProvider.image)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .accessibilityLabel(assetProvider.marketingName + " logo")
                        Text(assetProvider.marketingName)
                            .font(.title)
                            .fontDesign(.serif)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if !advancedFields.isEmpty {
                Section("Advanced", isExpanded: $advancedExpanded) {
                    ForEach(advancedFields) { field in
                        fieldView(for: field)
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add \((wrapper.provider as? AssetProvider.Type)?.marketingName ?? wrapper.provider.id)")
        .background {
            if let assetProvider = wrapper.provider as? AssetProvider.Type {
                assetProvider.background
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add", role: .confirm) {
                    addProvider()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
        }
    }

    /// A two-way binding into `values` for a given field, falling back to the
    /// field's default value when the user hasn't typed anything yet.
    private func binding(for field: ProviderField) -> Binding<String> {
        Binding(
            get: { values[field.key] ?? field.defaultValue },
            set: { values[field.key] = $0 }
        )
    }

    @ViewBuilder
    private func fieldView(for field: ProviderField) -> some View {
        switch field.kind {
        case .text:
            TextField(field.name, text: binding(for: field), prompt: Text(field.placeholder))
        case .secure:
            SecureField(field.name, text: binding(for: field), prompt: Text(field.placeholder))
        }
    }

    /// Requires every standard (non-advanced) field to have a non-empty value
    /// before the provider can be added.
    private var canSubmit: Bool {
        standardFields.allSatisfy { field in
            !binding(for: field).wrappedValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }
    }

    /// Builds a concrete provider from the collected input and dismisses on
    /// success, surfacing any validation error inline.
    private func addProvider() {
        do {
            let configuredProvider = ConfiguredProvider(providerID: wrapper.provider.id)
            
            for (key, value) in values {
                configuredProvider.saveConfigurationValue(for: key, with: value)
            }
            
            modelContext.insert(configuredProvider)
            try modelContext.save()
            dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
    }
}

#Preview {
    NavigationStack {
        AddProviderForm(wrapper: ProviderWrapper(provider: AnthropicProvider.self))
    }
}
