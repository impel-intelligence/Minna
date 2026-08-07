//
//  LocalModelRepo.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 8/5/26.
//

import Foundation
import HuggingFace
import ModelCDN
import Hub

public protocol Downloader: Sendable {
    func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error>
    func listModels() throws -> [DownloadedModel]
}

public final class LocalModelRepo: Sendable {
    enum RepoError: Error {
        case modelDoesNotExistOnDisk
    }

    public static let shared: LocalModelRepo = LocalModelRepo()
    let modelCDNDownloader = ModelCDNDownloader()
    let huggingFaceDownloader = HuggingFaceDownloader()

    private init() { }

    public func getModel(id: String) throws -> DownloadedModel {
        guard let model = try modelCDNDownloader.listModels().first(where: { $0.id == id }) else {
            throw RepoError.modelDoesNotExistOnDisk
        }

        return model
    }

    public func availableModels() throws -> [DownloadedModel] {
        return try modelCDNDownloader.listModels()
    }

    /// Downloads a model from the Hugging Face Hub into the shared model storage directory.
    ///
    /// Once the returned stream finishes, the model is visible to ``availableModels()``.
    ///
    /// - Parameter id: A Hub repository identifier such as `mlx-community/Nanbeige4.1-3B-8bit`.
    /// - Returns: A stream of ``Progress`` values covering the download.
    /// - Authored by: Claude Opus 5 (Anthropic)
    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
        try huggingFaceDownloader.downloadModel(id: id)
    }
}

public final class ModelCDNDownloader: /*Downloader,*/ Sendable {
    public init() { }

    public func listModels() throws -> [DownloadedModel] {
        try DownloadedModel.models(in: ManifestSharedSettings.modelStorageURL)
    }

//    public func downloadModel(id: String) throws -> AsyncThrowingStream<Progress, Error> {
//
//    }
}
