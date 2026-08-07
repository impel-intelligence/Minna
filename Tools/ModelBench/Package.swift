// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Created by Claude Opus 5 (Anthropic) on 2026-08-06.

import PackageDescription

let package = Package(
    name: "ModelBench",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(path: "../../Packages/MinnaChat"),
        .package(path: "../../Packages/IrisSearch"),
        .package(path: "../../Packages/ModelCDN"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.0.0"),
        // Mirrors MinnaChat's own declarations so the MLX trait resolves identically here.
        // SwiftPM warns that mlx-swift-lm is unused by any target — that is correct and
        // intentional: the harness generates only through AnyLanguageModel, and this package is
        // declared solely so the resolved graph matches the app's.
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "3.0.0"),
        .package(url: "https://github.com/impel-intelligence/AnyLanguageModel", from: "2.2.0", traits: ["MLX"])
    ],
    targets: [
        .executableTarget(
            name: "ModelBench",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MinnaChat", package: "MinnaChat"),
                .product(name: "ModelManager", package: "MinnaChat"),
                .product(name: "IrisSearch", package: "IrisSearch"),
                .product(name: "IrisCommon", package: "IrisSearch"),
                .product(name: "CoreMLEmbedder", package: "IrisSearch"),
                .product(name: "AppleIntelligenceEmbedder", package: "IrisSearch"),
                .product(name: "ModelCDN", package: "ModelCDN"),
                // Used only to count output tokens with each model's own tokenizer. Generation
                // goes through AnyLanguageModel, never through mlx-swift-lm directly.
                .product(name: "Tokenizers", package: "swift-transformers")
            ],
            resources: [
                .copy("Resources/corpus"),
                .copy("Resources/suite.json")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
