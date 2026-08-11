//
//  DownloadingModelView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/11/26.
//

import SwiftUI
import ModelManager
import DatabaseSchema
import SFSafeSymbols
import ModelCDN

struct DownloadingModelView: View {
    @Environment(ModelManager.self) var modelManager
    @Environment(OnboardingNavigationRouter.self) var onboardingRouter
    @Environment(\.openURL) var openURL

    let canSkipDownload: Bool
    let modelIdentifier: String
    
    @State private var isDownloadComplete: Bool = false

    private var currentDownload: DownloadingFile? {
        return modelManager.inFlightDownloads.first(where: { $0.id == modelIdentifier })
    }

    var body: some View {
        Group {
            if let download = currentDownload {
                downloading(file: download)
            } else {
                ContentUnavailableView {
                    Label("Download Failed", systemSymbol: .exclamationmarkTriangle)
                } description: {
                    Text("The on-device model could not be downloaded at this time.")
                } actions: {
                    if canSkipDownload {
                        Button("Skip Downloading") {
                            onboardingRouter.inferenceFinished(modelManager: modelManager)
                        }
                    } else {
                        Button("Contact Support") {
                            if let url = URL(string: "mailto:support@tryminna.com?subject=Failed%20to%20download%20on-device%20model") {
                                openURL(url)
                            }
                        }
                    }

                    Button("Set up off-device providers") {
                        onboardingRouter.recoverTopProviders()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .onChange(of: modelManager.inFlightDownloads) { oldValue, newValue in
            let wasDownloading = oldValue.contains(where: { $0.id == modelIdentifier })
            let isNowDownloading = newValue.contains(where: { $0.id == modelIdentifier })
            if wasDownloading && !isNowDownloading {
                onboardingRouter.inferenceFinished(modelManager: modelManager)
            }
        }
        .onAppear {
            if modelManager.doesModelExistOnDisk(identifier: modelIdentifier) {
                onboardingRouter.inferenceFinished(modelManager: modelManager)
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
                .accessibilityHidden(true)

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

                if canSkipDownload {
                    Button("Next") {
                        onboardingRouter.inferenceFinished(modelManager: modelManager)
                    }
                    .controlSize(.extraLarge)
                    .buttonStyle(.borderedProminent)
                }
            }

            if canSkipDownload {
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
    }
}

#Preview {
    DownloadingModelView(canSkipDownload: false, modelIdentifier: "bge_small_en_v1.5")
        .environment(ModelManager())
        .environment(OnboardingNavigationRouter())
}
