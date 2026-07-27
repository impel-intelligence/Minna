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
        
        guard let manifest = try? Manifest.load(from: manifestURL) else {
            Log.logger.error("Unable to decode manifest.")
            return []
        }
        
        do {
            try manifest.save(to: ManifestSharedSettings.localManifestURL)
            Log.logger.info("Saved local copy of manifest to \(ManifestSharedSettings.localManifestURL)!")
        } catch {
            Log.logger.error("Failed to save local copy of manifest", error: error)
        }
        
        // Parse the file at `manifestURL` to determine what assets are available
        // that might need to be scheduled for download.
        // Note: A downloads's identifier should be unique. It is what is used to track your
        // download between the extension and app.

        // Then, create a set of downloads to return to the system.
        var downloadsToSchedule: Set<BADownload> = []
        
        switch (request) {
        case .install, .update:
            // In an install or update request, you can return both Essential and Non-Essential downloads.
            // Essential downloads will be started by the system while your app is installing/updating,
            // and the user cannot launch the app until they complete or fail.
            // To mark a download as Essential, pass `true` for the `essential` initializer argument.
            for asset in manifest.files {
                Log.logger.info("Adding \(asset.identifier) to download list!")
                // TODO: Only download a file if the platform matches
                
                let download = BAURLDownload(
                    identifier: asset.identifier,
                    request: URLRequest(url: asset.url),
                    essential: asset.required,
                    fileSize: asset.fileSize,
                    applicationGroupIdentifier: appGroupIdentifier,
                    priority: .default
                )

                downloadsToSchedule.insert(download)
            }
            
            break
        case .periodic:
            // In a periodic request, you can only return Non-Essential downloads.
            // Non-Essential downloads occur in the background and will not prevent the
            // user from launching your app.
            // To mark a download as Non-Essential, pass `false` for the `essential` initializer argument.
            
            for asset in manifest.files {
                Log.logger.info("Adding \(asset.identifier) to download list!")
                // TODO: Only download a file if the platform matches
                
                let download = BAURLDownload(
                    identifier: asset.identifier,
                    request: URLRequest(url: asset.url),
                    essential: false,
                    fileSize: asset.fileSize,
                    applicationGroupIdentifier: appGroupIdentifier,
                    priority: .default
                )

                downloadsToSchedule.insert(download)
            }

            break
        @unknown default:
            return Set()
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
            try FileManager.default.moveItem(at: fileURL, to: archiveURL)
            
//            guard try Archive.validateSHA(expectedHash: downloadingFile.file.hash, file: archiveURL) else {
//                Log.logger.error("SHA256 hash of downloaded archive does not match manifest")
//                return
//            }
            
            let outputURL = ManifestSharedSettings.modelStorageURL.appendingPathComponent(finishedDownload.identifier, conformingTo: .directory)
            try Archive.extract(file: archiveURL, to: outputURL)

        } catch {
            
        }
//        FileManager.default.moveItem(at: fileURL, to: <#T##URL#>)
    }
}
