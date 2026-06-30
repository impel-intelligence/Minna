//
//  DownloaderTests.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 6/29/26.
//

import Testing
@testable import ModelManager
import Cocoa

struct DownloaderTests {

    @Test func testModelDownload() async throws {
        let downloader = ModelDownloader()
        for try await progress in await downloader.downloadModel(id: "mlx-community/whisper-tiny") {
            print(progress)
        }
    }

}
