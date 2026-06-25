//
//  Settings.swift
//  Manifests
//
//  Created by Taylor Lineman on 6/12/26.
//

import ProjectDescription

public enum FileAccess: String {
    case readWrite
    case readOnly
    case none = "NO"
    
    var settingValue: SettingValue {
        .string(rawValue)
    }
}

extension SettingsDictionary {
    /// Sets `"ARCHS"` to `architecture`
    public func architecture(_ architecture: String) -> SettingsDictionary {
        merging(["ARCHS": .string(architecture)])
    }
    
    /// Sets `"COMBINE_HIDPI_IMAGES"` to `combine`
    public func combineHIDPIImages(_ combine: Bool) -> SettingsDictionary {
        merging(["COMBINE_HIDPI_IMAGES": SettingValue(booleanLiteral: combine)])
    }
    
    /// Sets `"DEAD_CODE_STRIPPING"` to `strip`
    public func deadCodeStripping(_ strip: Bool) -> SettingsDictionary {
        merging(["DEAD_CODE_STRIPPING": SettingValue(booleanLiteral: strip)])
    }
    
    /// Sets:
    /// - `ENABLE_HARDENED_RUNTIME` to `hardenedRuntime` (Default: `true`).
    /// - `RUNTIME_EXCEPTION_ALLOW_DYLD_ENVIRONMENT_VARIABLES` to `allowDyldEnvironmentVariables` (Default: `false`).
    /// - `RUNTIME_EXCEPTION_ALLOW_JIT` to `allowJIT` (Default: `false`).
    /// - `RUNTIME_EXCEPTION_ALLOW_UNSIGNED_EXECUTABLE_MEMORY` to `allowUnsignedExecutableMemory` (Default: `false`).
    /// - `RUNTIME_EXCEPTION_DEBUGGING_TOOL` to `debuggingTool` (Default: `false`).
    /// - `RUNTIME_EXCEPTION_DISABLE_EXECUTABLE_PAGE_PROTECTION` to `disableExecutablePageProtection` (Default: `false`).
    /// - `RUNTIME_EXCEPTION_DISABLE_LIBRARY_VALIDATION` to `disableLibraryValidation` (Default: `false`).
    public func hardenedRuntime(
        hardenedRuntime: Bool = true,
        allowDyldEnvironmentVariables: Bool = false,
        allowJIT: Bool = false,
        allowUnsignedExecutableMemory: Bool = false,
        debuggingTool: Bool = false,
        disableExecutablePageProtection: Bool = false,
        disableLibraryValidation: Bool = false
    ) -> SettingsDictionary {
        merging([
            "ENABLE_HARDENED_RUNTIME": SettingValue(booleanLiteral: hardenedRuntime),
            "RUNTIME_EXCEPTION_ALLOW_DYLD_ENVIRONMENT_VARIABLES": SettingValue(booleanLiteral: allowDyldEnvironmentVariables),
            "RUNTIME_EXCEPTION_ALLOW_JIT": SettingValue(booleanLiteral: allowJIT),
            "RUNTIME_EXCEPTION_ALLOW_UNSIGNED_EXECUTABLE_MEMORY": SettingValue(booleanLiteral: allowUnsignedExecutableMemory),
            "RUNTIME_EXCEPTION_DEBUGGING_TOOL": SettingValue(booleanLiteral: debuggingTool),
            "RUNTIME_EXCEPTION_DISABLE_EXECUTABLE_PAGE_PROTECTION": SettingValue(booleanLiteral: disableExecutablePageProtection),
            "RUNTIME_EXCEPTION_DISABLE_LIBRARY_VALIDATION": SettingValue(booleanLiteral: disableLibraryValidation),
        ])
    }
    
    /// Sets resource access settings. Requires `ENABLE_APP_SANDBOX` or `ENABLE_HARDENED_RUNTIME`.
    ///
    /// Sets:
    /// - `ENABLE_RESOURCE_ACCESS_AUDIO_INPUT` to `audioInput` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_BLUETOOTH` to `bluetooth` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_CALENDARS` to `calendars` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_CAMERA` to `camera` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_CONTACTS` to `contacts` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_LOCATION` to `location` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_PHOTO_LIBRARY` to `photoLibrary` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_PRINTING` to `printing` (Default: `false`).
    /// - `ENABLE_RESOURCE_ACCESS_USB` to `usb` (Default: `false`).
    public func resourceAccess(audioInput: Bool = false,
                               bluetooth: Bool = false,
                               calendars: Bool = false,
                               camera: Bool = false,
                               contacts: Bool = false,
                               location: Bool = false,
                               photoLibrary: Bool = false,
                               printing: Bool = false,
                               usb: Bool = false
    ) -> SettingsDictionary {
        merging([
            "ENABLE_RESOURCE_ACCESS_AUDIO_INPUT": SettingValue(booleanLiteral: audioInput),
            "ENABLE_RESOURCE_ACCESS_BLUETOOTH": SettingValue(booleanLiteral: bluetooth),
            "ENABLE_RESOURCE_ACCESS_CALENDARS": SettingValue(booleanLiteral: calendars),
            "ENABLE_RESOURCE_ACCESS_CAMERA": SettingValue(booleanLiteral: camera),
            "ENABLE_RESOURCE_ACCESS_CONTACTS": SettingValue(booleanLiteral: contacts),
            "ENABLE_RESOURCE_ACCESS_LOCATION": SettingValue(booleanLiteral: location),
            "ENABLE_RESOURCE_ACCESS_PHOTO_LIBRARY": SettingValue(booleanLiteral: photoLibrary),
            "ENABLE_RESOURCE_ACCESS_PRINTING": SettingValue(booleanLiteral: printing),
            "ENABLE_RESOURCE_ACCESS_USB": SettingValue(booleanLiteral: usb),
        ])
    }
    
    /// Sets:
    /// - `ENABLE_USER_SCRIPT_SANDBOXING` to `sandboxed`.
    public func userScriptSandboxing(_ sandboxed: Bool) -> SettingsDictionary {
        merging([
            "ENABLE_USER_SCRIPT_SANDBOXING": SettingValue(booleanLiteral: sandboxed)
        ])
    }

    /// Sets:
    /// - `ENABLE_APP_SANDBOX` to `sandboxed`.
    /// - `ENABLE_INCOMING_NETWORK_CONNECTIONS` to `incomingNetworkConnections` (Default: `false`).
    /// - `ENABLE_OUTGOING_NETWORK_CONNECTIONS` to `outgoingNetworkConnections` (Default: `false`).
    /// - `ENABLE_USER_SELECTED_FILES` to `userSelectedFiles` (Default: `.none`).
    /// - `ENABLE_FILE_ACCESS_DOWNLOADS_FOLDER` to `downloadsFolder` (Default: `.none`).
    /// - `ENABLE_FILE_ACCESS_PICTURE_FOLDER` to `pictureFolder` (Default: `.none`).
    /// - `ENABLE_FILE_ACCESS_MUSIC_FOLDER` to `musicFolder` (Default: `.none`).
    /// - `ENABLE_FILE_ACCESS_MOVIES_FOLDER` to `moviesFolder` (Default: `.none`).
    public func appSandbox(sandboxed: Bool,
                           incomingNetworkConnections: Bool = false,
                           outgoingNetworkConnections: Bool = false,
                           userSelectedFiles: FileAccess = .none,
                           downloadsFolder: FileAccess = .none,
                           pictureFolder: FileAccess = .none,
                           musicFolder: FileAccess = .none,
                           moviesFolder: FileAccess = .none
    ) -> SettingsDictionary {
        merging([
            "ENABLE_APP_SANDBOX": SettingValue(booleanLiteral: sandboxed),
            "ENABLE_INCOMING_NETWORK_CONNECTIONS": SettingValue(booleanLiteral: incomingNetworkConnections),
            "ENABLE_OUTGOING_NETWORK_CONNECTIONS": SettingValue(booleanLiteral: outgoingNetworkConnections),
            "ENABLE_USER_SELECTED_FILES": userSelectedFiles.settingValue,
            "ENABLE_FILE_ACCESS_DOWNLOADS_FOLDER": downloadsFolder.settingValue,
            "ENABLE_FILE_ACCESS_PICTURE_FOLDER": pictureFolder.settingValue,
            "ENABLE_FILE_ACCESS_MUSIC_FOLDER": musicFolder.settingValue,
            "ENABLE_FILE_ACCESS_MOVIES_FOLDER": moviesFolder.settingValue,

        ])
    }

    /// Sets:
    /// - `STRING_CATALOG_GENERATE_SYMBOLS` to `generateStringCatalogSymbols` (Default: `true`).
    /// - `SWIFT_EMIT_LOC_STRINGS` to `emitLocStrings` (Default: `true`).
    public func localizedStrings(generateStringCatalogSymbols: Bool = true, emitLocStrings: Bool = true) -> SettingsDictionary {
        merging([
            "STRING_CATALOG_GENERATE_SYMBOLS": SettingValue(booleanLiteral: generateStringCatalogSymbols),
            "SWIFT_EMIT_LOC_STRINGS": SettingValue(booleanLiteral: emitLocStrings),
        ])
    }
}

public let irisBaseSettings = SettingsDictionary()
    .automaticCodeSigning(devTeam: DEV_TEAM)
    .codeSignIdentityAppleDevelopment()
//    .appleGenericVersioningSystem()
    .currentProjectVersion(BUILD_NUMBER)
    .marketingVersion(MARKETING_VERSION)
    .debugInformationFormat(.dwarfWithDsym)
    .swiftVersion("6.0")
    .architecture("arm64") // TODO: Remove
    .deadCodeStripping(true) // Apple Silicon only: faiss / faiss_c xcframeworks ship no x86_64 macOS slice, so a universal (x86_64) archive fails to link. Pin to arm64.
    .hardenedRuntime()
    .localizedStrings()
    .userScriptSandboxing(true)
    .appSandbox(sandboxed: true, incomingNetworkConnections: true, userSelectedFiles: .readOnly, downloadsFolder: .readOnly)

public let irisSettings: Settings = .settings(
    base: irisBaseSettings,
    configurations: [
        .debug(name: "Debug", settings: [
            "GCC_OPTIMIZATION_LEVEL" : .string("0"),
            "LD_RUNPATH_SEARCH_PATHS": .string("$(inherited) @executable_path/../Frameworks")
        ]),
        .release(name: "Release", settings: [
            "GCC_OPTIMIZATION_LEVEL" : .string("3"),
            "LD_RUNPATH_SEARCH_PATHS": .string("$(inherited) @executable_path/../Frameworks")
        ])
    ]
)

// Signing-only settings for test bundles. A test bundle is loaded into the
// host app's process, so dyld requires its Team ID to match the host's.
// Without this the test targets sign ad-hoc (Team ID "not set") and fail to
// load into the Team-ID-signed Iris.app with a "different Team IDs" error.
public let irisTestSettings: Settings = .settings(
    base: SettingsDictionary().automaticCodeSigning(devTeam: DEV_TEAM).codeSignIdentityAppleDevelopment()
)
