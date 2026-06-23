//
//  Settings.swift
//  Manifests
//
//  Created by Taylor Lineman on 6/12/26.
//

import ProjectDescription

public let TARGET_MACOS_VERSION = "26.0"
public let APP_STAGE = "alpha"
public let CURRENT_PROJECT_VERSION = "0.1.0"
public let MARKETING_VERSION = "\(CURRENT_PROJECT_VERSION)"
public let PRODUCT_BUNDLE_IDENTIFIER = "com.tryiris.iris.mac"

public let irisSettings: Settings = .settings(
    base: [
        "ASSETCATALOG_COMPILER_APPICON_NAME" : .string("AppIcon"),
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": .string("AccentColor"),
//        "CODE_SIGN_IDENTITY": .string("Apple Development"),
        "CODE_SIGN_STYLE": .string("Automatic"),
        "COMBINE_HIDPI_IMAGES": .string("YES"),
        "DEAD_CODE_STRIPPING": .string("YES"),
        "DEBUG_INFORMATION_FORMAT": .string("dwarf-with-dsym"),
//        "DEVELOPMENT_TEAM": .string(""),
        "ENABLE_HARDENED_RUNTIME": .string("YES"),
        "ENABLE_PREVIEWS": .string("YES"),
        "MACOSX_DEPLOYMENT_TARGET": .string(TARGET_MACOS_VERSION),
        "CURRENT_PROJECT_VERSION": .string(CURRENT_PROJECT_VERSION),
        "MARKETING_VERSION": .string(MARKETING_VERSION),
        "PRODUCT_BUNDLE_IDENTIFIER": .string(PRODUCT_BUNDLE_IDENTIFIER),
        "TARGET_NAME": .string("Iris"),
        "PRODUCT_NAME": .string("Iris"),
        "SWIFT_VERSION": .string("5.0"),
        
        // MARK: Localization
        "STRING_CATALOG_GENERATE_SYMBOLS": .string("YES"),
        "SWIFT_EMIT_LOC_STRINGS": .string("YES"),
        
        // MARK: Sandboxing
        "ENABLE_APP_SANDBOX": .string("YES"),
        "ENABLE_USER_SCRIPT_SANDBOXING": .string("YES"),
        "ENABLE_USER_SELECTED_FILES": .string("readonly"),
        "ENABLE_INCOMING_NETWORK_CONNECTIONS": .string("NO"),
        "ENABLE_OUTGOING_NETWORK_CONNECTIONS": .string("YES"),
        
        // MARK: Sandbox / Hardened Runtime
        "ENABLE_RESOURCE_ACCESS_AUDIO_INPUT": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_BLUETOOTH": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_CALENDARS": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_CAMERA": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_CONTACTS": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_LOCATION": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_PHOTO_LIBRARY": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_PRINTING": .string("NO"),
        "ENABLE_RESOURCE_ACCESS_USB": .string("NO"),
        
        // MARK: Hardened Runtime
        "RUNTIME_EXCEPTION_ALLOW_DYLD_ENVIRONMENT_VARIABLES": .string("NO"),
        "RUNTIME_EXCEPTION_ALLOW_JIT": .string("NO"),
        "RUNTIME_EXCEPTION_ALLOW_UNSIGNED_EXECUTABLE_MEMORY": .string("NO"),
        "RUNTIME_EXCEPTION_DEBUGGING_TOOL": .string("NO"),
        "RUNTIME_EXCEPTION_DISABLE_EXECUTABLE_PAGE_PROTECTION": .string("NO"),
        "RUNTIME_EXCEPTION_DISABLE_LIBRARY_VALIDATION": .string("NO"),
        
        "COMPILATION_CACHE_ENABLE_CACHING": .string("YES"),
        "COMPILATION_CACHE_REMOTE_SERVICE_PATH": .string("$HOME/.local/state/tuist/Impel-Intelligence_Iris.sock"),
        "COMPILATION_CACHE_ENABLE_PLUGIN": .string("YES"),
        "COMPILATION_CACHE_ENABLE_DIAGNOSTIC_REMARKS": .string("YES"),
    ],
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

// - For All of our OBJ-C dependencies
// https://docs.tuist.io/guide/project/dependencies#objective-c-dependencies

