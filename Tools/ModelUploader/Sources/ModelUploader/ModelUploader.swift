// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import CoreML
import AppleArchive
import System
import Subprocess
import ModelCDN
import CryptoKit

@main
struct ModelUploader: AsyncParsableCommand {
    static let coreMLExtensions = ["mlpackage", "mlmodel", "mlmodelc"]
    static let googleBucket = "gs://minna_embedding_models"
    static let cdnDomain = URL(string: "https://cdn.tryminna.com")!
    static let manifest = "manifest.json"
    
    enum UploadError: Error {
        case unknownModelFormat
        case modelURLDoesNotExist
        case couldNotFindCompiledModel
        case missingVocab
        case missingConfig
        
        case couldNotCreateFileStream
        case couldNotCreateCompressionStream
        case couldNotCreateEncodingStream
        case couldNotCreateKeySet
        case couldNotFetchManifest
        
        case couldNotGetFileSize
    }
    
    @Argument(help: "The marketing name of the model.")
    var name: String
    
    @Argument(help: "The identifier of the model.")
    var identifier: String
    
    @Argument(help: "The CoreML model to upload to the Minna CDN.", completion: .file(extensions: coreMLExtensions))
    var modelPath: String
    
    @Option(help: "Is this a required download for the app to function")
    var required: Bool

    mutating func run() async throws {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        guard var modelURL = URL(string: modelPath, relativeTo: currentDirectory) else {
            throw UploadError.modelURLDoesNotExist
        }
        
        guard ModelUploader.coreMLExtensions.contains(modelURL.pathExtension) else {
            throw UploadError.unknownModelFormat
        }
        
        let modelDirectory = modelURL.deletingLastPathComponent()
        
        let vocabURL = modelDirectory.appendingPathComponent("vocab", conformingTo: .plainText)
        
        guard FileManager.default.fileExists(atPath: vocabURL.path(percentEncoded: false)) else {
            throw UploadError.missingVocab
        }
        
        let configURL = modelDirectory.appendingPathComponent("config", conformingTo: .json)
        
        guard FileManager.default.fileExists(atPath: configURL.path(percentEncoded: false)) else {
            throw UploadError.missingConfig
        }
        
        print("Resolved Config and Vocab files.")
        
        // If the package is not a compiled CoreML model, compile it.
        if modelURL.pathExtension == "mlpackage" || modelURL.pathExtension == "mlmodel" {
            print("Compiling \(modelURL.pathExtension)...")
            modelURL = try await MLModel.compileModel(at: modelURL)
            print("Done compiling \(modelURL.pathExtension)!")
        }
        
        let temporaryDirectory = FileManager.default.temporaryDirectory.appending(path: "model_uploader")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let packageDirectory = temporaryDirectory.appending(path: name)
        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: packageDirectory) }
        
        print("Copying model")
        // Move the model into the temp directory
        try FileManager.default.copyItem(at: modelURL, to: packageDirectory.appending(path: "model.mlmodelc"))
        
        print("Copying config")
        // Move the configuration file
        try FileManager.default.copyItem(at: configURL, to: packageDirectory.appending(path: "config.json"))
        
        print("Copying vocab")
        // Move the vocabulary file
        try FileManager.default.copyItem(at: vocabURL, to: packageDirectory.appending(path: "vocab.txt"))
                
        print("Creating Archive Streams")
        let archiveFile = temporaryDirectory.appendingPathComponent(name, conformingTo: .appleArchive)
        let archiveFilePath = FilePath(stringLiteral: archiveFile.path(percentEncoded: false))
        
        guard let writeFileStream = ArchiveByteStream.fileStream(
            path: archiveFilePath,
            mode: .writeOnly,
            options: [ .create ],
            permissions: FilePermissions(rawValue: 0o644)) else {
            throw UploadError.couldNotCreateFileStream
        }
        
        defer { try? writeFileStream.close() }

        guard let compressStream = ArchiveByteStream.compressionStream(using: .lzfse, writingTo: writeFileStream) else {
            throw UploadError.couldNotCreateCompressionStream
        }
        
        defer { try? compressStream.close() }
        
        guard let encodeStream = ArchiveStream.encodeStream(writingTo: compressStream) else {
            throw UploadError.couldNotCreateCompressionStream
        }
        
        defer { try? encodeStream.close() }

        // Create a key set with the defaults, except UID or GID
        guard let keySet = ArchiveHeader.FieldKeySet("TYP,PAT,LNK,DEV,DAT,MOD,FLG,MTM,BTM,CTM") else {
            throw UploadError.couldNotCreateKeySet
        }
        
        print("Archiving Model")
        let packagePath = FilePath(packageDirectory.path(percentEncoded: false))
        try encodeStream.writeDirectoryContents(archiveFrom: packagePath, keySet: keySet)
        
        print("Calculating SHA256 hash")
        
        let archiveData = try Data(contentsOf: archiveFile)
        let hash = SHA256.hash(data: archiveData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        print("Retrieving Existing Manifest")
        let manifestFile = temporaryDirectory.appending(path: ModelUploader.manifest)
        try await downloadFromCDN(file: ModelUploader.manifest, to: manifestFile)
        
        var manifest: Manifest
        if FileManager.default.fileExists(atPath: manifestFile.path(percentEncoded: false)) {
            print("Manifest found!")
            manifest = try Manifest.load(from: manifestFile)
        } else {
            print("No manifest found, creating a new one.")
            manifest = Manifest(files: [])
        }
        
        let sizeValues = try archiveFile.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = sizeValues.fileSize else {
            throw UploadError.couldNotGetFileSize
        }

        if manifest.files.contains(where: { $0.identifier == identifier }) {
            manifest.files.removeAll(where: { $0.identifier == identifier })
            try? await deleteFromCDN(file: identifier)
        }
        
        let fileURL = ModelUploader.cdnDomain.appendingPathComponent(name, conformingTo: .appleArchive)
        let file = Manifest.File(
            identifier: identifier,
            fileSize: fileSize,
            url: fileURL,
            platforms: [.macOS],
            required: required,
            hash: hashString
        )
        
        manifest.files.append(file)
        
        print("Saving manifest file")
        try manifest.save(to: manifestFile)
        
        print("Uploading Manifest File")
        try await uploadToCDN(file: manifestFile)
        
        print("Uploading archive to google cloud")
        try await uploadToCDN(file: archiveFile)
    }
    
    func deleteFromCDN(file: String) async throws {
        let arguments: Arguments = ["storage", "rm", file]
        let config: Subprocess.Configuration = .init(.path("/opt/homebrew/bin/gcloud"), arguments: arguments)
        
        _ = try await Subprocess.run(config, output: .currentStandardOutput, error: .combinedWithOutput)
    }
    
    func downloadFromCDN(file: String, to url: URL) async throws {
        let downloadURL = ModelUploader.googleBucket + "/" + file
        let arguments: Arguments = ["storage", "cp", downloadURL, url.absoluteString]
        let config: Subprocess.Configuration = .init(.path("/opt/homebrew/bin/gcloud"), arguments: arguments)
        
        _ = try await Subprocess.run(config, output: .currentStandardOutput, error: .combinedWithOutput)
    }
    
    func uploadToCDN(file: URL) async throws {
        let arguments: Arguments = ["storage", "cp", file.absoluteString, ModelUploader.googleBucket]
        let config: Subprocess.Configuration = .init(.path("/opt/homebrew/bin/gcloud"), arguments: arguments)
        
        _ = try await Subprocess.run(config, output: .currentStandardOutput, error: .combinedWithOutput)
    }
}
