//
//  ListCommand.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import ArgumentParser
import Foundation
import ModelCDN
import ModelManager

/// Lists every model Minna can currently run, with its on-disk size.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the models available on this machine."
    )

    func run() async throws {
        let models = try LocalModelRepo.shared.availableModels()

        guard !models.isEmpty else {
            print("No models found in \(ManifestSharedSettings.modelStorageURL.path(percentEncoded: false)).")
            print("Download one with: modelbench fetch mlx-community/Nanbeige4.1-3B-8bit")
            return
        }

        print("Models in \(ManifestSharedSettings.modelStorageURL.path(percentEncoded: false)):")

        for model in models {
            let size = (try? ByteCount.ofDirectory(model.directory)) ?? 0
            print("  \(model.id.padding(toLength: max(34, model.id.count), withPad: " ", startingAt: 0))  \(size.formattedBytes)")
        }
    }
}
