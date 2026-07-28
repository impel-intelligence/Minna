//
//  Archive.swift
//  ModelCDN
//
//  Created by Taylor Lineman on 7/27/26.
//

import Foundation
import AppleArchive
import UniformTypeIdentifiers
import System
import CryptoKit

public extension SHA256.Digest {
    var hexString: String { self.compactMap { String(format: "%02x", $0) }.joined() }
}

public struct Archive {
    public enum ArchiveError: Error {
        case couldNotCreateFileStream
        case couldNotCreateCompressionStream
        case couldNotCreateEncodingStream
        case couldNotCreateKeySet
        case couldNotFetchManifest
        case couldNotCreateDecompressionStream
        case couldNotCreateDecodeStream
        case couldNotCreateExtractionStream
        
        case invalidHash
    }
    
    /// Write a file to an Apple Archive to be saved at `outputPath`
    /// - Parameters:
    ///   - file: The file or directory to archive
    ///   - outputURL: The path to output the Apple Archive to.
    public static func write(file: URL, to outputURL: URL) throws {
        let outputPath = FilePath(stringLiteral: outputURL.path(percentEncoded: false))
        
        guard let writeFileStream = ArchiveByteStream.fileStream(
            path: outputPath,
            mode: .writeOnly,
            options: [ .create ],
            permissions: FilePermissions(rawValue: 0o644)) else {
            throw ArchiveError.couldNotCreateFileStream
        }
        
        defer { try? writeFileStream.close() }

        guard let compressStream = ArchiveByteStream.compressionStream(using: .lzfse, writingTo: writeFileStream) else {
            throw ArchiveError.couldNotCreateCompressionStream
        }
        
        defer { try? compressStream.close() }
        
        guard let encodeStream = ArchiveStream.encodeStream(writingTo: compressStream) else {
            throw ArchiveError.couldNotCreateCompressionStream
        }
        
        defer { try? encodeStream.close() }

        // Create a key set with the defaults, except UID or GID
        guard let keySet = ArchiveHeader.FieldKeySet("TYP,PAT,LNK,DEV,DAT,MOD,FLG,MTM,BTM,CTM") else {
            throw ArchiveError.couldNotCreateKeySet
        }
        
        let archivePath = FilePath(file.path(percentEncoded: false))
        try encodeStream.writeDirectoryContents(archiveFrom: archivePath, keySet: keySet)
    }
    
    public static func extract(file: URL, to extractionURL: URL)  throws {
        let archiveFilePath = FilePath(stringLiteral: file.path(percentEncoded: false))
        
        guard let readFileStream = ArchiveByteStream.fileStream(
                path: archiveFilePath,
                mode: .readOnly,
                options: [ ],
                permissions: FilePermissions(rawValue: 0o644)) else {
            throw ArchiveError.couldNotCreateFileStream
        }
        
        defer { try? readFileStream.close() }
        
        guard let decompressStream = ArchiveByteStream.decompressionStream(readingFrom: readFileStream) else {
            throw ArchiveError.couldNotCreateDecompressionStream
        }
        
        defer { try? decompressStream.close() }


        guard let decodeStream = ArchiveStream.decodeStream(readingFrom: decompressStream) else {
            throw ArchiveError.couldNotCreateDecodeStream
        }
        
        defer { try? decodeStream.close() }

        let extractionPath = extractionURL.path(percentEncoded: false)
        
        if !FileManager.default.fileExists(atPath: extractionPath) {
            try FileManager.default.createDirectory(atPath: extractionPath, withIntermediateDirectories: false)
        }
        
        let decompressDestination = FilePath(extractionPath)

        guard let extractStream = ArchiveStream.extractStream(extractingTo: decompressDestination,
                                                              flags: [ .ignoreOperationNotPermitted ]) else {
            throw ArchiveError.couldNotCreateExtractionStream
        }
        
        defer { try? extractStream.close() }

        _ = try ArchiveStream.process(readingFrom: decodeStream, writingTo: extractStream)
    }
    
    public static func hash(file: URL) throws -> SHA256.Digest {
        let archiveData = try Data(contentsOf: file)
        return SHA256.hash(data: archiveData)
    }
    
    public static func validateSHA(expectedHash: String, file: URL) throws -> Bool {
        guard let expectedHashData = expectedHash.data(using: .hexadecimal) else {
            throw ArchiveError.invalidHash
        }
        
        let newHash = try hash(file: file)
        return newHash.elementsEqual(expectedHashData)
    }
}

