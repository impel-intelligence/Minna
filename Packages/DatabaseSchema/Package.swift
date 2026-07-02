// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DatabaseSchema",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DatabaseSchema",
            targets: ["DatabaseSchema"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "24.0.0"),
//        .package(url: "https://github.com/huggingface/AnyLanguageModel", from: "0.8.0"),
        .package(url: "https://github.com/impel-intelligence/AnyLanguageModel", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DatabaseSchema",
            dependencies: [
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel")
            ]
        ),

    ],
    swiftLanguageModes: [.v6]
)
