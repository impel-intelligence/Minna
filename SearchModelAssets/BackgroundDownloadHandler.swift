//
//  BackgroundDownloadHandler.swift
//  SearchModelAssets
//
//  Created by Taylor Lineman on 7/24/26.
//

import BackgroundAssets
import ExtensionFoundation
import ModelCDN
import Logging
import UniformTypeIdentifiers

@main
struct BackgroundDownloadHandler: BADownloaderExtension {
    func downloads(for request: BAContentRequest,
                   manifestURL: URL,
                   extensionInfo: BAAppExtensionInfo) -> Set<BADownload> {
        Log.logger.info("Starting download request \(request)")

        // Invoked by the system to request downloads from your extension.
        // The BAContentRequest argument will contain the reason downloads are requested.
        // The system will pre-download the contents of the URL specified in the `BAManifestURL`
        // key in your app's `Info.plist` before calling into your extension. The `manifestURL`
        // argument will point to a read-only file containing those contents. You are encouraged
        // to use this file to determine what assets need to be downloaded.
        
        let appGroupIdentifier = ManifestSharedSettings.appGroupIdentifier
        
        // Load the manifest from the download URL.
        guard let manifest = try? Manifest.load(from: manifestURL) else {
            Log.logger.error("Unable to decode manifest.")
            return []
        }
        
        // Save a copy of the manifest so it can be accessed by the main app.
        do {
            try manifest.save(to: ManifestSharedSettings.localManifestURL)
            Log.logger.info("Saved local copy of manifest to \(ManifestSharedSettings.localManifestURL)!")
        } catch {
            Log.logger.error("Failed to save local copy of manifest", error: error)
        }
        
        // Create a set of downloads to return to the system.
        var downloadsToSchedule: Set<BADownload> = []
        
        for asset in manifest.files {
            guard asset.platforms.contains(where: { $0.matches() }) else {
                Log.logger.info("Skipping \(asset.name) since it is not for this platform.")
                continue
            }
            
            // An asset is essential if this is an app `install` or an `update` & it has been marked required.
            // Other types of installs do not support essential downloads so we skip essentials for them.
            let isEssential = (request == .install || request == .update) ? asset.required : false
            
            let download = BAURLDownload(
                identifier: asset.identifier,
                request: URLRequest(url: asset.url),
                essential: isEssential,
                fileSize: asset.fileSize,
                applicationGroupIdentifier: appGroupIdentifier,
                priority: .default
            )

            downloadsToSchedule.insert(download)
        }

        // The downloads that are returned will be downloaded automatically by the system.
        return downloadsToSchedule
    }

    func backgroundDownload(_ failedDownload: BADownload, failedWithError error: Error) {
        // Extension was woken because a download failed.
        // A download can be rescheduled with BADownloadManager if necessary.
        Log.logger.error("Failed to download \(failedDownload.identifier)", error: error)
    }

    func backgroundDownload(_ finishedDownload: BADownload, finishedWithFileURL fileURL: URL) {
        // Extension was woken because a download finished.
        // It is strongly advised to keep files in `Library/Caches` so that they may be
        // deleted when the device becomes low on storage.
        Log.logger.info("Finished downloading \(finishedDownload.identifier) to \(fileURL)")
        
        do {
            let archiveURL = ManifestSharedSettings.modelStorageURL.appendingPathComponent(finishedDownload.identifier, conformingTo: .appleArchive)

            // Remove any existing archive
            if FileManager.default.fileExists(atPath: archiveURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: archiveURL)
            }

            // Write the new archive
            try FileManager.default.moveItem(at: fileURL, to: archiveURL)

            let outputURL = ManifestSharedSettings.modelStorageURL.appendingPathComponent(finishedDownload.identifier, conformingTo: .directory)
            try Archive.extract(file: archiveURL, to: outputURL)

            // Remove the archive now that we are done with it.
            try FileManager.default.removeItem(at: archiveURL)
        } catch {
            Log.logger.error("Finished downloading \(finishedDownload.identifier) to \(fileURL)", error: error)
        }
    }
}
