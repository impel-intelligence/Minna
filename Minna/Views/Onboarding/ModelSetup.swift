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

struct OnDeviceSetup: View {
    @Environment(ModelManager.self) var modelManager
    @AppStorage("onboarding") var isOnboarding: Bool = true

    @State private var isDownloadComplete: Bool = false

    private var currentDownload: DownloadingFile? {
        guard let inferenceModel = modelManager.standardInferenceModel else { return nil }
        return modelManager.inFlightDownloads.first(where: { $0.id == inferenceModel })
    }

    var body: some View {
        Group {
            if isDownloadComplete {
                downloadComplete()
            } else if let download = currentDownload {
                downloading(file: download)
            } else {
                ContentUnavailableView("No model can be downloaded at this time", systemSymbol: .exclamationmarkTriangle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .onChange(of: modelManager.inFlightDownloads) { oldValue, newValue in
            guard let inferenceModel = modelManager.standardInferenceModel else { return }
            let wasDownloading = oldValue.contains(where: { $0.id == inferenceModel })
            let isNowDownloading = newValue.contains(where: { $0.id == inferenceModel })
            if wasDownloading && !isNowDownloading {
                isDownloadComplete = true
            }
        }
        .onAppear {
            modelManager.standardInferenceModel = "qwen3-4b-4bit"
            if let inferenceModel = modelManager.standardInferenceModel,
               modelManager.doesModelExistOnDisk(identifier: inferenceModel) {
                isDownloadComplete = true
            }
        }
    }

    @ViewBuilder
    func downloading(file: DownloadingFile) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemSymbol: .squareAndArrowDown)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75, height: 75)

            Text("Downloading \(file.file.name)")
                .font(.title)
                .fontWeight(.semibold)

            Text("Minna is downloading the required on-device models.")
                .frame(width: 300)

            ProgressView(file.progress)
                .frame(width: 300)

            HStack {
                NavigationLink("Set up off-device providers") {
                    ProviderSetupView()
                }
                .controlSize(.extraLarge)

                Button("Start adding content") {
                    isOnboarding = false
                }
                .controlSize(.extraLarge)
                .buttonStyle(.borderedProminent)
            }

            Text("\(Image(systemSymbol: .exclamationmarkCircle)) You will not be able to chat wth your content until the download is complete.")
                .frame(width: 300)
                .foregroundStyle(.red)
                .font(.caption)
        }
    }

    @ViewBuilder
    func downloadComplete() -> some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemSymbol: .checkmark)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75, height: 75)

            Text("Finished downloading!")
                .font(.title)
                .fontWeight(.semibold)

            Button("Get started!") {
                isOnboarding = false
            }
            .controlSize(.extraLarge)
            .buttonStyle(.borderedProminent)
        }
    }
}

struct ProviderSetupView: View {
    @State var providerWrapper: ProviderWrapper?

    var body: some View {
        // Provider list
        ScrollView {
            VStack(alignment: .leading) {
                Text("Select a model Provider")
                buttonFor(provider: AnthropicProvider.self)
                buttonFor(provider: OpenAIProvider.self)
                buttonFor(provider: OllamaProvider.self)
                buttonFor(provider: GeminiProvider.self)
            }
        }
//        // Form
//        if let providerWrapper {
//            Divider()
//            ProviderConfigurationForm(wrapper: providerWrapper)
//        } else {
//            Spacer()
//        }
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
        .buttonStyle(.plain)
        .contentShape(.rect)
        .accessibilityLabel("Add \(provider.marketingName) as a model provider.")
    }
}

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
        .navigationBarBackButtonHidden()
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
