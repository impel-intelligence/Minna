//
//  ModelDownloadProgress.swift
//  MinnaChat
//
//  Created by Claude Opus 4.8 (Anthropic) on 2026-06-29
//

import Foundation
import Observation

@Observable @MainActor
public final class ModelDownloadProgress {
    public enum Phase: Equatable {
        case idle
        case downloading(fraction: Double, bytesPerSecond: Double?)
        case loading           // weights on disk, MLX loading into memory
        case ready
        case failed(String)
    }
    
    public var phase: Phase = .idle
    
    /// 0.0–1.0 for the download portion; nil when not downloading.
    public var fraction: Double? {
        if case .downloading(let f, _) = phase { return f }
        return nil
    }
}
