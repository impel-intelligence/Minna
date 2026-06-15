// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "Iris",
    dependencies: [
        // Add your own dependencies here:
        // .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
        // You can read more about dependencies here: https://docs.tuist.io/documentation/tuist/dependencies
//        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "9.17.1"),
        .package(url: "https://github.com/ActuallyTaylor/SFSymbols", from: "7.0.0"),
        .package(url: "https://github.com/impel-intelligence/ViewStorage", from: "1.3.0"),
    ]
)
