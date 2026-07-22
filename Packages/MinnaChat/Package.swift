// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Edited by Claude Opus 4.8 (Anthropic) on 2026-07-01: added AnyLanguageModel dependency to the ModelManager target.

import PackageDescription

let package = Package(
    name: "MinnaChat",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MinnaChat",
            targets: ["MinnaChat"]
        ),
        .library(
            name: "ModelManager",
            targets: ["ModelManager"]
        )
    ],
    dependencies: [
        .package(path: "../DatabaseSchema"),
        .package(path: "../IrisSearch"),
        .package(url: "https://github.com/impel-intelligence/AnyLanguageModel", from: "2.0.0")
//        .package(path: "/Users/taylorlineman/Developer/git/AnyLanguageModel"),
//        .package(
//            url: "https://github.com/huggingface/AnyLanguageModel",
//            from: "0.8.0",
//            traits: ["MLX"]
//        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MinnaChat",
            dependencies: [
                "DatabaseSchema",
                "ModelManager",
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel"),
                .product(name: "IrisSearch", package: "IrisSearch")
            ]
        ),
        .target(
            name: "ModelManager",
            dependencies: [
                "DatabaseSchema",
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
