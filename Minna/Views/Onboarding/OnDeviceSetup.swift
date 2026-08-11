//
//  OnDeviceSetup.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

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
                ContentUnavailableView {
                    Label("Download Failed", systemSymbol: .exclamationmarkTriangle)
                } description: {
                    Text("The on-device model could not be downloaded at this time.")
                } actions: {
                    Button("Skip Downloading") {
                        isOnboarding = false
                    }

                    NavigationLink("Set up off-device providers") {
                        ProviderSetupView()
                    }
                }
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

            HStack(alignment: .top) {
                Image(systemSymbol: .exclamationmarkCircle)
                    .accessibilityLabel("Notice:")
                Text("You will not be able to chat wth your content until the download is complete.")
            }
            .frame(width: 300)
            .foregroundStyle(.red)
            .font(.callout)
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
