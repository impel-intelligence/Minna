//
//  FetchCommand.swift
//  ModelBench
//
//  Created by Claude Opus 5 (Anthropic) on 2026-08-06.
//

import ArgumentParser
import Foundation
import ModelCDN
import ModelManager

/// Downloads candidate models from the Hugging Face Hub into Minna's shared model storage.
///
/// - Authored by: Claude Opus 5 (Anthropic)
struct Fetch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fetch",
        abstract: "Download one or more models from the Hugging Face Hub."
    )

    @Argument(help: "Hub repository identifiers, for example mlx-community/Nanbeige4.1-3B-8bit.")
    var repositories: [String]

    func run() async throws {
        let downloader = HuggingFaceDownloader()

        for repository in repositories {
            let name = repository.split(separator: "/").last.map(String.init) ?? repository

            if let existing = try? downloader.listModels().first(where: { $0.id == name }) {
                print("• \(repository) already present at \(existing.directory.path(percentEncoded: false))")
                continue
            }

            print("↓ \(repository)")
            let start = ContinuousClock.now
            var lastPercent = -1

            for try await progress in try downloader.downloadModel(id: repository) {
                let percent = Int(progress.fractionCompleted * 100)
                guard percent != lastPercent else { continue }
                lastPercent = percent
                FileHandle.standardError.write(Data("\r  \(percent)%".utf8))
            }

            FileHandle.standardError.write(Data("\r".utf8))

            let directory = ManifestSharedSettings.modelStorageURL.appending(path: name, directoryHint: .isDirectory)
            let size = (try? ByteCount.ofDirectory(directory)) ?? 0
            print("✓ \(repository) — \(size.formattedBytes) in \(start.durationDescription)")
        }
    }
}

extension Int64 {
    /// A human-readable byte count, for example `4.18 GB`.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var formattedBytes: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}

extension ContinuousClock.Instant {
    /// The elapsed time since this instant, rendered as seconds with one decimal place.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var durationDescription: String {
        let elapsed = ContinuousClock.now - self
        return String(format: "%.1fs", elapsed.seconds)
    }
}

extension Duration {
    /// This duration expressed as fractional seconds.
    ///
    /// - Authored by: Claude Opus 5 (Anthropic)
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}

/// Byte accounting helpers for on-disk model directories.
///
/// - Authored by: Claude Opus 5 (Anthropic)
enum ByteCount {
    /// Sums the size of every regular file beneath `directory`.
    ///
    /// Hidden files are skipped so a model that was `git clone`d is measured by its weights
    /// rather than by its weights plus the `.git` copy of them.
    ///
    /// - Parameter directory: The directory to measure.
    /// - Returns: The total size in bytes.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static func ofDirectory(_ directory: URL) throws -> Int64 {
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return 0
        }

        var total: Int64 = 0

        while let fileURL = enumerator.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values.isRegularFile == true, let size = values.fileSize else { continue }
            total += Int64(size)
        }

        return total
    }
}
