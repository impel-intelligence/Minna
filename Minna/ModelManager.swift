//
//  ModelManager.swift
//  Minna
//
//  Created by Taylor Lineman on 7/27/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-07-27
//

import Foundation
import Logging
import BackgroundAssets
import Synchronization
import ModelCDN
import UniformTypeIdentifiers

struct DownloadDidFinish : NotificationCenter.MainActorMessage {
    public typealias Subject = ModelManager
    
    public static var name: Notification.Name {
        .init("ModelManager.DownloadDidFinish")
    }

    public let identifier: String
}

extension NotificationCenter.MessageIdentifier where Self == NotificationCenter.BaseMessageIdentifier<DownloadDidFinish> {
    static var downloadDidFinish: Self { .init() }
}

struct DownloadingFile: Identifiable {
    var id: String { file.identifier }
    
    let file: Manifest.File
    var progress: Progress
}

@Observable
final class ModelManager: NSObject, @unchecked Sendable {
    
    @ObservationIgnored
    private let manifest: Mutex<Manifest> = Mutex(Manifest(files: []))
    
    public var inFlightDownloads: [DownloadingFile] = []
    
    private let stateLock = NSLock()

    override init() {
        super.init()
        BADownloadManager.shared.delegate = self
        
        do {
            try self.loadLocalManifest()
        } catch {
            Log.logger.error("Failed to load local manifest", error: error)
        }
    }

    private func refreshManifest() async throws {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let manifestURLString = infoDictionary["BAManifestURL"] as? String,
              let manifestURL = URL(string: manifestURLString) else {
            Log.logger.error("Failed to retrieve manifest URL.")
            return
        }
        
        let request = URLRequest(url: manifestURL)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Overwrite any existing manifest settings
        try? FileManager.default.removeItem(at: ManifestSharedSettings.localManifestURL)
        try data.write(to: ManifestSharedSettings.localManifestURL)
        
        // Load the local manifest file if we have successfully wrote the new manifest.
        try loadLocalManifest()
    }
    
    private func loadLocalManifest() throws {
        // Check to see if the Manifest file exists on disk. If it doesn't try and load it from the internet.
        guard FileManager.default.fileExists(atPath: ManifestSharedSettings.localManifestURL.path(percentEncoded: false)) else {
            Log.logger.error("No remote manifest has been downloaded at \(ManifestSharedSettings.localManifestURL).")
            
            // Dispatch a metadata refresh.
            Task {
                do {
                    try await refreshManifest()
                } catch {
                    Log.logger.error("Failed to manually refresh metadata", error: error)
                }
            }

            return
        }
        
        try manifest.withLock { manifest in
            manifest = try Manifest.load(from: ManifestSharedSettings.localManifestURL)
            
            // We always need the required files, so instruct them to download
            for file in manifest.files.filter(\.required) {
                // Only download files that are not on the disk already.
                guard !doesModelExistOnDisk(identifier: file.identifier) else { continue }
                
                self.startDownload(of: file)
            }
            
            // TODO: This should not be hard coded
            if let qwen = manifest.files.filter({ $0.identifier == "Qwen3.5-9B-MLX-4bit" }).first,
               !doesModelExistOnDisk(identifier: qwen.identifier) {
                print("Downloading QWEN Model!")
                self.startDownload(of: qwen)
            }
        }
    }
    
    private func doesModelExistOnDisk(identifier: String) -> Bool {
        let url = ManifestSharedSettings.modelStorageURL.appendingPathComponent(identifier, conformingTo: .directory)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    private func startDownload(of file: Manifest.File) {
        BADownloadManager.shared.withExclusiveControl { lockAcquired, error in
            guard lockAcquired else {
                Log.logger.warning("Failed to acquire lock", error: error)
                return
            }
            
            do {
                let download: BADownload
                let currentDownloads = try BADownloadManager.shared.fetchCurrentDownloads()

                // If this session is already being downloaded, promote it to the foreground.
                if let existingDownload = currentDownloads.first(where: { $0.identifier == file.identifier }) {
                    // `startForegroundDownload` cannot be called with an essential download (it traps rather than throwing) — Essential downloads may only be enqueued by the extension.
                    download = existingDownload.isEssential ? existingDownload.removingEssential() : existingDownload
                } else {
                    download = BAURLDownload(
                        identifier: file.identifier,
                        request: URLRequest(url: file.url),
                        essential: false,
                        fileSize: file.fileSize,
                        applicationGroupIdentifier: ManifestSharedSettings.appGroupIdentifier,
                        priority: .default
                    )
                }
                
                Task { @MainActor in
                    self.stateLock.withLock {
                        self.inFlightDownloads.append(DownloadingFile(file: file, progress: Progress()))
                    }
                }
                                
                guard download.state != .failed else {
                    Log.logger.warning("Download for session \(file.identifier) is in the failed state.")
                    return
                }
                
                try BADownloadManager.shared.startForegroundDownload(download)
            } catch {
                Log.logger.warning("Failed to start download for session \(file.identifier)", error: error)
            }
        }
    }
}

// Delegate Methods fire on BackgroundAssets' own queue, not the main actor's executor — `nonisolated` is required or the @objc entry point traps on the isolation check.
extension ModelManager: BADownloadManagerDelegate {
    nonisolated func download(_ download: BADownload, didWriteBytes bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite totalExpectedBytes: Int64) {
        // Ignore `BAManifestURL` downloads while handling progress.
        guard type(of: download) == BAURLDownload.self else {
            return
        }
        
        let progress = Progress(totalUnitCount: totalExpectedBytes)
        progress.completedUnitCount = totalBytesWritten
        
        Task { @MainActor [weak self] in
            Log.logger.info("\(download.identifier) (\(progress.fractionCompleted.formatted(.percent)))")
            self?.stateLock.withLock {
                guard let currentFileIndex = self?.inFlightDownloads.firstIndex(where: { $0.file.identifier == download.identifier }) else {
                    return
                }
                
                self?.inFlightDownloads[currentFileIndex].progress = progress
            }
        }
    }
    
    nonisolated func download(_ download: BADownload, failedWithError error: any Error) {
        // If the `BAManifestURL` fails to download, the BADownloadManager's delegate is notified about it.
        // The type of the manifest is not a `BAURLDownload`, therefore you can key off of
        // the download's type to filter it out.
        guard type(of: download) == BAURLDownload.self else {
            Log.logger.error("Download of unsupported type failed: \(download.identifier)", error: error)
            return
        }
        
        Log.logger.error("Download failed \(download.identifier) \(error)", error: error)
    }
    
    nonisolated func download(_ download: BADownload, finishedWithFileURL fileURL: URL) {
        Log.logger.info("Finished download \(download.identifier) to \(fileURL)")
        do {
            let archiveURL = ManifestSharedSettings.modelStorageURL.appendingPathComponent(download.identifier, conformingTo: .appleArchive)

            // Remove any existing archive
            if FileManager.default.fileExists(atPath: archiveURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: archiveURL)
            }

            // Write the new archive
            try FileManager.default.moveItem(at: fileURL, to: archiveURL)

            let outputURL = ManifestSharedSettings.modelStorageURL.appendingPathComponent(download.identifier, conformingTo: .directory)
            try Archive.extract(file: archiveURL, to: outputURL)

            // Remove the archive now that we are done with it.
            try FileManager.default.removeItem(at: archiveURL)
            
            Task { @MainActor in
                NotificationCenter.default.post(DownloadDidFinish(identifier: download.identifier))

                self.stateLock.withLock {
                    inFlightDownloads.removeAll { $0.id == download.identifier }
                }
            }
        } catch {
            Log.logger.error("Failed to finish download for \(download.identifier), \(error)")
        }
    }
}
