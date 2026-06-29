// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MinnaChat",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MinnaChat",
            targets: ["MinnaChat"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/huggingface/AnyLanguageModel",
            from: "0.8.0",
            traits: ["MLX"]
        ),
        .package(url: "https://github.com/impel-intelligence/IrisSearch", from: "0.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MinnaChat",
            dependencies: [
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel"),
                .product(name: "IrisSearch", package: "IrisSearch")
            ]
        ),

    ],
    swiftLanguageModes: [.v6]
)
