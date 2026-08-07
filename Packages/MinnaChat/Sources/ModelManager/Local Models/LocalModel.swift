//
//  LocalModel.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/5/26.
//  Edited by Claude Opus 5 (Anthropic) on 2026-08-06: added the shared model-directory scan.
//

import Foundation

public struct DownloadedModel: Model, Sendable, Hashable, Equatable {
    public enum Runner: Int, Sendable {
        case mlx
        
        var provider: any ModelProvider.Type {
            switch self {
            case .mlx:
                return MLXProvider.self
            }
        }
    }
    
    public let id: String
    public let displayName: String
    public let runner: Runner
    public var provider: any ModelProvider.Type {
        return runner.provider
    }
    
    public let directory: URL

    public init(id: String, displayName: String, runner: Runner, directory: URL) {
        self.id = id
        self.displayName = displayName
        self.runner = runner
        self.directory = directory
    }
    
    public var hashValue: Int {
        return id.hashValue + displayName.hashValue + directory.hashValue + runner.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(runner)
        hasher.combine(directory)
    }

    public static func == (lhs: DownloadedModel, rhs: DownloadedModel) -> Bool {
        lhs.id == rhs.id && lhs.displayName == rhs.displayName && lhs.runner == rhs.runner && lhs.directory == rhs.directory
    }
}

public extension DownloadedModel {
    /// Lists every runnable chat model in a model storage directory.
    ///
    /// A subdirectory counts as a model when it holds `.safetensors` weights alongside a
    /// `.jinja` chat template, which is the layout both the CDN and Hub downloaders produce.
    /// The subdirectory name is the model's identifier.
    ///
    /// - Parameter storageDirectory: The directory holding one subdirectory per model.
    /// - Returns: Every model found, in directory order.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func models(in storageDirectory: URL) throws -> [DownloadedModel] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var downloadedModels: [DownloadedModel] = []

        for directory in contents where ((try? directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false) {
            let directoryID = directory.lastPathComponent
            let directoryContents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [])

            // If there is .safetensors, and a jinja chat template this is a valid chat model.
            guard directoryContents.contains(where: { $0.pathExtension == "safetensors" }) else { continue }
            guard directoryContents.contains(where: { $0.pathExtension == "jinja" }) else { continue }

            downloadedModels.append(DownloadedModel(id: directoryID, displayName: directoryID, runner: .mlx, directory: directory))
        }

        return downloadedModels
    }
}
