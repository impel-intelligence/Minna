//
//  ProviderConfigurationForm.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import SwiftData
import DatabaseSchema
import SFSafeSymbols
import ModelManager

struct ProviderConfigurationForm: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    let wrapper: ProviderWrapper

    /// The user's input, keyed by `ProviderField.key`. This dictionary is the
    /// single source of truth the form collects; on "Add" it is handed straight
    /// to the provider's factory to build a configured provider.
    @State private var values: [String: String] = [:]
    @State private var advancedExpanded: Bool = false
    @State private var errorMessage: String?
    
    @State private var configurationName: String = ""
    
    @FocusState private var focusedField: String?

    private var fields: [ProviderField] { wrapper.provider.fields }
    private var standardFields: [ProviderField] { fields.filter { !$0.isAdvanced } }
    private var advancedFields: [ProviderField] { fields.filter { $0.isAdvanced } }
    
    private var providerName: String {
        ((wrapper.provider as? AssetProvider.Type)?.marketingName ?? wrapper.provider.id)
    }

    var body: some View {
        Form {
            Section {
                TextField("Configuration Name", text: $configurationName, prompt: Text(providerName))
                    .focused($focusedField, equals: "name")
                
                ForEach(standardFields) { field in
                    fieldView(for: field)
                }
            } header: {
                VStack(alignment: .center) {
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
                    HStack(spacing: 2) {
                        Text("Configuration stored in Keychain")
                        Image(systemSymbol: .lockFill)
                            .accessibilityHidden(true)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .onAppear {
            if let config = wrapper.existingConfiguration {
                self.configurationName = config.name
                
                for field in fields where values[field.key] == nil {
                    values[field.key] = config.getConfigurationValue(for: field.key)
                }
            } else if configurationName.isEmpty {
                configurationName = providerName
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add \(providerName)")
        .background {
            if let assetProvider = wrapper.provider as? AssetProvider.Type {
                assetProvider.background
            }
        }
        .toolbar {
            if let config = wrapper.existingConfiguration {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(config)
                        NotificationCenter.default.post(name: .configuredProvidersChanged, object: self)
                        dismiss()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(wrapper.existingConfiguration == nil ? "Add" : "Update", role: .confirm) {
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
            get: { values[field.key] ?? field.defaultValue ?? "" },
            set: { values[field.key] = $0 }
        )
    }

    @ViewBuilder
    private func fieldView(for field: ProviderField) -> some View {
        switch field.kind {
        case .text:
            TextField(field.name, text: binding(for: field), prompt: Text(field.placeholder))
                .focused($focusedField, equals: field.key)
        case .secure:
            SecureField(field.name, text: binding(for: field), prompt: Text(field.placeholder))
                .focused($focusedField, equals: field.key)
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
            let uuid: UUID = wrapper.existingConfiguration?.id ?? UUID()
            let configuredProvider = ConfiguredProvider(id: uuid, name: configurationName, providerID: wrapper.provider.id)
            
            for (key, value) in values {
                configuredProvider.saveConfigurationValue(for: key, with: value)
            }
            
            // Load all default values
            for field in wrapper.provider.fields where values[field.key] == nil {
                guard let defaultValue = field.defaultValue else {
                    throw ProviderConfigurationError.missingField(field.key)
                }
                
                configuredProvider.saveConfigurationValue(for: field.key, with: defaultValue)
            }
            
            modelContext.insert(configuredProvider)
            try modelContext.save()
            NotificationCenter.default.post(name: .configuredProvidersChanged, object: self)
            dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ProviderConfigurationForm(wrapper: ProviderWrapper(provider: AnthropicProvider.self, existingConfiguration: nil))
    }
}
