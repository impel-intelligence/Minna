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

struct DownloadDidFinish: NotificationCenter.MainActorMessage {
    public typealias Subject = ModelManager
    
    public static var name: Notification.Name {
        .init("ModelManager.DownloadDidFinish")
    }

    public let identifier: String
}

extension NotificationCenter.MessageIdentifier where Self == NotificationCenter.BaseMessageIdentifier<DownloadDidFinish> {
    static var downloadDidFinish: Self { .init() }
}

struct DownloadingFile: Identifiable, Equatable {
    var id: String { file.identifier }
    
    let file: Manifest.File
    var progress: Progress
}

@Observable
final class ModelManager: NSObject, @unchecked Sendable {
    static let maxDownloadAttempts: Int = 3
    
    @ObservationIgnored
    private let manifest: Mutex<Manifest> = Mutex(Manifest(files: []))
    
    public var standardInferenceModel: String? = nil
    
    public var inFlightDownloads: [DownloadingFile] = []
    
    private let stateLock = NSLock()

    override init() {
        super.init()
        BADownloadManager.shared.delegate = self
        
        do {
            try self.loadLocalManifest(attempts: 0)
        } catch {
            Log.logger.error("Failed to load local manifest", error: error)
        }
    }

    private func refreshManifest(attempts: Int) async throws {
        guard attempts <= ModelManager.maxDownloadAttempts else {
            Log.logger.error("Failed to download ModelCDN manifest after \(attempts) attempts.")
            return
        }
        
        guard let infoDictionary = Bundle.main.infoDictionary,
              let manifestURLString = infoDictionary["BAManifestURL"] as? String,
              let manifestURL = URL(string: manifestURLString) else {
            Log.logger.error("Failed to retrieve manifest URL.")
            return
        }
        
        // Progressive backoff on the attempts
        if attempts > 0 {
            Log.logger.info("Waiting \(5 * attempts) seconds before trying to fetch the manifest")
            try? await Task.sleep(for: .seconds(5 * attempts))
        }
        
        let request = URLRequest(url: manifestURL)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Overwrite any existing manifest settings
        try? FileManager.default.removeItem(at: ManifestSharedSettings.localManifestURL)
        try data.write(to: ManifestSharedSettings.localManifestURL)
        
        // Load the local manifest file if we have successfully wrote the new manifest.
        try loadLocalManifest(attempts: attempts)
    }
    
    private func loadLocalManifest(attempts: Int) throws {
        // Check to see if the Manifest file exists on disk. If it doesn't try and load it from the internet.
        if !FileManager.default.fileExists(atPath: ManifestSharedSettings.localManifestURL.path(percentEncoded: false)) {
            Log.logger.error("No remote manifest has been downloaded at \(ManifestSharedSettings.localManifestURL).")
            
            // Dispatch a metadata refresh.
            startRefreshTask(attempts: attempts)
            return
        }
        
        do {
            let manifest = try manifest.withLock { manifest in
                manifest = try Manifest.load(from: ManifestSharedSettings.localManifestURL)
                return manifest
            }
            
            // We always need the required files, so instruct them to download. We also only download embedding models since inference models are handled by the
            for file in manifest.files.filter(\.required) {
                // Set the standard inference model to the model that is required and an inference model.
                if file.required && file.type == .inference {
                    standardInferenceModel = file.identifier
                }
                
                // Only download files that are not on the disk already.
                guard !doesModelExistOnDisk(identifier: file.identifier) else { continue }
                
                self.startDownload(of: file)
            }
        } catch {
            Log.logger.error("Failed to load manifest, redownloading.", error: error)
            startRefreshTask(attempts: attempts)
        }
    }
    
    private func startRefreshTask(attempts: Int) {
        Task {
            do {
                try await refreshManifest(attempts: attempts + 1)
            } catch {
                Log.logger.error("Failed to manually refresh metadata", error: error)
            }
        }
    }
    
    public func doesModelExistOnDisk(identifier: String) -> Bool {
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
                                                
                guard download.state != .failed else {
                    Log.logger.warning("Download for session \(file.identifier) is in the failed state.")
                    return
                }
                
                Task { @MainActor in
                    self.stateLock.withLock {
                        let progress = Progress()
                        progress.kind = .file
                        self.inFlightDownloads.append(DownloadingFile(file: file, progress: progress))
                    }
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
        progress.kind = .file
        
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
        
        Task { @MainActor in
            self.stateLock.withLock {
                self.inFlightDownloads.removeAll(where: {$0.id == download.identifier})
            }
        }
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
