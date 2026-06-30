//
//  DownloaderTests.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/29/26.
//

import Testing
@testable import ModelManager

struct DownloaderTests {

    @Test func testModelDownload() async throws {
        let downloader = ModelDownloader()
        try await downloader.downloadModel(id: "mlx-community/whisper-tiny")
    }

}
