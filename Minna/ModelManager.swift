//
//  ModelManager.swift
//  Minna
//
//  Created by Taylor Lineman on 7/27/26.
//

import Foundation
import Logging
import BackgroundAssets
import Synchronization
import ModelCDN

final class ModelManager: NSObject {
    
    private let manifest: Mutex<Manifest> = Mutex(Manifest(files: []))

    override init() {
        super.init()
        BADownloadManager.shared.delegate = self
        
        self.loadLocalManifest()
    }

    func refreshManifest() {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let manifestURLString = infoDictionary["BAManifestURL"] as? String,
              let manifestURL = URL(string: manifestURLString) else {
            Log.logger.error("Failed to retrieve manifest URL.")
            return
        }

        let downloadTask = URLSession.shared.downloadTask(with: manifestURL) { url, response, error in
            guard let url = url else {
                Log.logger.error("Manifest download failed. Response: \(response)", error: error)
                return
            }
            
            do {
                _ = try FileManager.default.replaceItemAt(ManifestSharedSettings.localManifestURL, withItemAt: url)
            } catch {
                Log.logger.error("Failed to move manifest", error: error)
                return
            }
            
            
        }
        
        downloadTask.resume()
    }

    private func loadLocalManifest() {
        let localManifestURL = ManifestSharedSettings.localManifestURL
        let exists = FileManager.default.fileExists(atPath: localManifestURL.path(percentEncoded: false))
        guard exists else {
            Log.logger.error("No remote manifest has been downloaded at \(ManifestSharedSettings.localManifestURL).")
            refreshManifest()
            return
        }
        
        do {
            try manifest.withLock { manifest in
                manifest = try Manifest.load(from: localManifestURL)
            }
        } catch {
            Log.logger.error("Failed to load manifest.", error: error)
            return
        }
        
        Task { @MainActor in
            self.manifest.withLock { manifest in
                for file in manifest.files {
                    self.startDownload(of: file)
//                    let shouldContinue = self.stateLock.withLock {
//                        // If you already have this session, skip it.
//                        if self.sessionSet.contains(session) {
//                            return true
//                        }
//                        
//                        self.sessionSet.insert(session)
//                        return false
//                    }
//                    if shouldContinue {
//                        continue
//                    }
//                    
//                    // Start downloading the new session if necessary.
//                    if session.state == .remote {
//                        self.startDownload(of: session)
//                    }
                }
            }
        }
    }

    func startDownload(of file: Manifest.File) {
        BADownloadManager.shared.withExclusiveControl { lockAcquired, error in
            guard lockAcquired else {
                Log.logger.warning("Failed to acquire lock", error: error)
                return
            }
            
            do {
                let download: BADownload
//                let currentDownloads = try BADownloadManager.shared.currentDownloads
//
//                // If this session is already being downloaded, promote it to the foreground.
//                if let existingDownload = currentDownloads.first(where: { $0.identifier == file.identifier }) {
//                    // `startForegroundDownload` cannot be called with an essential download (it traps
//                    // rather than throwing) — Essential downloads may only be enqueued by the extension.
//                    download = existingDownload.isEssential ? existingDownload.removingEssential() : existingDownload
//                } else {
                print(file.url)
                    download = BAURLDownload(
                        identifier: file.identifier,
                        request: URLRequest(url: file.url),
                        essential: false,
                        fileSize: file.fileSize,
                        applicationGroupIdentifier: ManifestSharedSettings.appGroupIdentifier,
                        priority: .default
                    )
//                }
                
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

extension ModelManager: BADownloadManagerDelegate {
    // These fire on BackgroundAssets' own XPC queue, not the main actor's executor —
    // `nonisolated` is required or the @objc entry point traps on the isolation check.
    nonisolated func download(_ download: BADownload, didWriteBytes bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite totalExpectedBytes: Int64) {
        // Ignore `BAManifestURL` downloads while handling progress.
        guard type(of: download) == BAURLDownload.self else {
            return
        }
        
        let progress = Double(totalBytesWritten) / Double(totalExpectedBytes)
        Log.logger.info("Download Progress: \(progress)")
        
//
//        guard let session = self.manifest.session(for: download.identifier) else {
//            Logger.app.warning("Unknown download: \(download.identifier)")
//            return
//        }
//
//        updateDownloadProgress(session, progress: progress)
    }
    
    nonisolated func download(_ download: BADownload, failedWithError error: any Error) {
        // If the `BAManifestURL` fails to download, the BADownloadManager's delegate is notified about it.
        // The type of the manifest is not a `BAURLDownload`, therefore you can key off of
        // the download's type to filter it out.
        guard type(of: download) == BAURLDownload.self else {
            Log.logger.error("Download of unsupported type failed: \(download.identifier)", error: error)
            return
        }

//        guard self.manifest.file(for: download.identifier) != nil else {
//            Logger.app.warning("Unknown download: \(download.identifier)")
//            return
//        }
//        
        Log.logger.error("Download failed \(download.identifier) \(error)", error: error)
    }
}
