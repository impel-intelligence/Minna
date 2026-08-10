//
//  LocalModel.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/5/26.
//

import Foundation
import ModelCDN

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
    public var displayName: String { configuration.displayName }
    public let runner: Runner
    public var provider: any ModelProvider.Type { return runner.provider }
    
    public let configuration: LLMModelConfig
    public let directory: URL

    public init(id: String, configuration: LLMModelConfig, runner: Runner, directory: URL) {
        self.id = id
        self.configuration = configuration
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
