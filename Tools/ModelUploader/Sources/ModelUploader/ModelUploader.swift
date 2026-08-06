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
        let temporaryDirectory = FileManager.default.temporaryDirectory.appending(path: "model_uploader")
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let packageDirectory = temporaryDirectory.appending(path: identifier)
        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: packageDirectory) }
        
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: modelPath, isDirectory: &isDirectory) else {
            throw UploadError.modelURLDoesNotExist
        }

        guard var modelURL = URL(string: modelPath, relativeTo: currentDirectory) else {
            throw UploadError.modelURLDoesNotExist
        }
        
        if isDirectory.boolValue == true {
            let configurationURL = modelURL.appendingPathComponent("minna-config", conformingTo: .json)
            
            if !FileManager.default.fileExists(atPath: configurationURL.path(percentEncoded: false)) {
                print("Creating Minna Configuration")
                
                let rawTemperature = ask(question: "Temperature")
                let rawTopP = ask(question: "Top P")
                let rawTopK = ask(question: "Top K")
                let rawMinP = ask(question: "Min P")
                let rawPresencePenalty = ask(question: "Presence Penalty")
                let rawRepetitionPenalty = ask(question: "Repetition Penalty")

                let configuration: LLMModelConfig = LLMModelConfig(
                    identifier: identifier,
                    displayName: name,
                    temperature: Double(rawTemperature ?? ""),
                    topP: Double(rawTopP ?? ""),
                    topK: Double(rawTopK ?? ""),
                    minP: Double(rawMinP ?? ""),
                    presencePenalty: Double(rawPresencePenalty ?? ""),
                    repetitionPenalty: Double(rawRepetitionPenalty ?? "")
                )

                try configuration.save(to: configurationURL)
            }

            let contents = try FileManager.default.contentsOfDirectory(at: modelURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

            for file in contents {
                let newURL = packageDirectory.appending(path: file.lastPathComponent)
                
                // Move the model into the temp directory
                try FileManager.default.copyItem(at: file, to: newURL)
            }
        } else if ModelUploader.coreMLExtensions.contains(modelURL.pathExtension) {
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
            
            print("Copying model")
            // Move the model into the temp directory
            try FileManager.default.copyItem(at: modelURL, to: packageDirectory.appending(path: "model.mlmodelc"))
    
            print("Copying config")
            // Move the configuration file
            try FileManager.default.copyItem(at: configURL, to: packageDirectory.appending(path: "config.json"))
    
            print("Copying vocab")
            // Move the vocabulary file
            try FileManager.default.copyItem(at: vocabURL, to: packageDirectory.appending(path: "vocab.txt"))
        } else {
            throw UploadError.unknownModelFormat
        }
            
        print("Archiving Model")
        let archiveFile = temporaryDirectory.appendingPathComponent(identifier, conformingTo: .appleArchive)
        try Archive.write(file: packageDirectory, to: archiveFile)
        
        let sha = try Archive.hash(file: archiveFile)
        let hashString = sha.compactMap { String(format: "%02x", $0) }.joined()
                
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
            try? await deleteFromCDN(file: identifier + ".aar")
        }
        
        let fileURL = ModelUploader.cdnDomain.appendingPathComponent(identifier, conformingTo: .appleArchive)
        let file = Manifest.File(
            identifier: identifier,
            name: name,
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
        let deleteURL = ModelUploader.googleBucket + "/" + file
        let arguments: Arguments = ["storage", "rm", deleteURL]
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
    
    func ask(question: String) -> String? {
        print("\(question): ", terminator: "")

        // 2. Read the standard input
        guard let value = readLine(), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return value
    }
}
