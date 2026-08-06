//
//  InstallModelsView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/30/26.
//

import SwiftUI
import ModelManager

struct InstallModelsView: View {
    var body: some View {
        Form {
            Section("Hugging Face") {

            }
        }
        .formStyle(.grouped)
        .navigationTitle("Install a Model")
        .onAppear {
            print(LocalModelRepo.shared.availableModels())
        }
        .task {
            do {
//                ModelCDNDownloader().listModels()
                
//                let progressStream = try LocalModelRepo.shared.download(id: "mlx-community/Qwen3.5-9B-MLX-4bit")
//
//                for try await progress in progressStream {
//                    fractionCompleted = progress.fractionCompleted
//                    if progress.totalUnitCount > 0 {
//                        // A parent Progress only folds a child's units into `completedUnitCount`
//                        // once that child finishes, so byte counts come from the fraction instead
//                        // to keep them in step with the bar.
//                        let completedBytes = Int64(progress.fractionCompleted * Double(progress.totalUnitCount))
//                        totalBytesFormatted = ByteCountFormatter.string(fromByteCount: progress.totalUnitCount, countStyle: .file)
//                        completedBytesFormatted = ByteCountFormatter.string(fromByteCount: completedBytes, countStyle: .file)
//                    }
//                }
            } catch {
                print("Failed to download model \(error)")
            }
        }
    }
}
