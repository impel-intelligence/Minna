import ProjectDescription


public let minnaInfoPlist: InfoPlist = .dictionary([
    // CF Values
    "CFBundleName": .string("$(PRODUCT_NAME)"),
    "CFBundleDevelopmentRegion": .string("$(DEVELOPMENT_LANGUAGE)"),
    "CFBundlePackageType": .string("$(PRODUCT_BUNDLE_PACKAGE_TYPE)"),
    "CFBundleInfoDictionaryVersion": .string("6.0"),
    "CFBundleExecutable": .string("$(EXECUTABLE_NAME)"),
    "CFBundleIdentifier": .string("$(PRODUCT_BUNDLE_IDENTIFIER)"),
    "CFBundleVersion": .string(BUILD_NUMBER),
    "CFBundleShortVersionString": .string(MARKETING_VERSION),
    
    // Exported Type Identifiers
    "UTExportedTypeDeclarations": [
        [
            "UTTypeDescription": "Minna Folder",
            "UTTypeIcons": [:],
            "UTTypeIdentifier": "\(PRODUCT_BUNDLE_IDENTIFIER).folder",
            "UTTypeTagSpecification": [
                "public.filename-extension": ["minnadb"],
                "public.mime-type": ["\(PRODUCT_BUNDLE_IDENTIFIER).folder"]
            ],
            "UTTypeConformsTo": ["com.apple.package", "public.content"]
        ]
    ],
    
    // Imported Type Identifiers
    "UTImportedTypeDeclarations": [
        [
            "UTTypeDescription": "Markdown",
            "UTTypeIcons": [:],
            "UTTypeIdentifier": "net.daringfireball.markdown",
            "UTTypeTagSpecification": [
                "public.filename-extension": ["md"],
                "public.mime-type": ["text/markdown", "text/x-markdown"]
            ],
            "UTTypeConformsTo": ["public.text", "public.data"]
        ]
    ],
    
//     Sparkle Values
    "SUFeedURL": .string("https://impel-intelligence.github.io/iris-sparkle-updater/appcast.xml"),
    "SUScheduledCheckInterval": .integer(21600),
    "SUPublicEDKey": .string("ySLQ5G0aOgmtZN2I2NnrPTwJZ36xgXcI3ZpY8W2wuBo="),

    // Other
    "LSApplicationCategoryType": .string("public.app-category.utilities"),
    
    // Usage Declarations
    "NSDesktopFolderUsageDescription": .string("Minna needs to access your Desktop to import content."),
    "NSDocumentsFolderUsageDescription": .string("Minna needs to access your Documents to import content."),
    "NSDownloadsFolderUsageDescription": .string("Minna needs to access your Downloads to import content."),
])
