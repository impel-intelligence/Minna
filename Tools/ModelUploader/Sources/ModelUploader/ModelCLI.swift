//
//  ModelCLI.swift
//  ModelUploader
//
//  Created by Taylor Lineman on 8/10/26.
//

import ArgumentParser

@main
struct ModelCLI: AsyncParsableCommand {
    // 1. Configure the root command and its subcommands
    static let configuration = CommandConfiguration(
        commandName: "modelCLI",
        abstract: "A utility for managing Minna's CDN models.",
        subcommands: [ModelUploader.self, ModelDeleter.self],
        defaultSubcommand: ModelUploader.self // Optional
    )
}
