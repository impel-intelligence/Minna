import ProjectDescription

public let irisInfoPlist: InfoPlist = .dictionary([
    // CF Values
    "CFBundleName": .string("$(PRODUCT_NAME)"),
    "CFBundleDevelopmentRegion": .string("$(DEVELOPMENT_LANGUAGE)"),
    "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
    "CFBundlePackageType": .string("$(PRODUCT_BUNDLE_PACKAGE_TYPE)"),
    "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
    "CFBundleInfoDictionaryVersion": .string("6.0"),
    "CFBundleExecutable": .string("$(EXECUTABLE_NAME)"),
    "CFBundleIdentifier": .string("$(PRODUCT_BUNDLE_IDENTIFIER)"),
    "CFBundleDisplayName": .string("Iris"),
    
    // Sparkle Values
//    "SUFeedURL": .string("https://impel-sparkle-updater.fly.dev/appcast.xml"),
//    "SUScheduledCheckInterval": .integer(21600),
//    "SUPublicEDKey": .string("TVcja488EICE+Z8F7XcTLvVq7a8TBwobbwlV87pJE10="),

    // Other
    "LSApplicationCategoryType": .string("public.app-category.utilities")
])
