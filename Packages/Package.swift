// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IrisSearch",
    platforms: [
        .macOS(.v15),
        .iOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "IrisCommon", targets: ["IrisCommon"]),
        .library(name: "IrisSearch", targets: ["IrisSearch"]),
        .library(name: "Digester", targets: ["Digester"]),
    ],
    dependencies: [
        .package(url: "https://github.com/impel-intelligence/SwiftFaiss", from: "0.4.1"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.11.0")
    ],
    targets: [
        // Common
        .target(
            name: "IrisCommon",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(name: "IrisCommonTests", dependencies: ["IrisCommon", "TestUtilities"]),
        
        // Test Utilities
        .target(
            name: "TestUtilities",
            dependencies: ["IrisCommon", "IrisSearch"],
            path: "Tests/Utilities" // Placed inside the Tests folder to keep Sources clean
        ),

        // Search
        .target(
            name: "IrisSearch",
            dependencies: [
                "IrisCommon",
                "SwiftFaiss",
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "IrisSearchTests",
            dependencies: [
                "IrisSearch",
                "TestUtilities"
            ],
            resources: [
                .copy("Test Documents")
            ]
        ),
        
        // Digester
        .target(
            name: "Digester",
            dependencies: ["IrisCommon"]
        ),
        .testTarget(
            name: "DigesterTests",
            dependencies: [
                "Digester",
                "TestUtilities"
            ],
            resources: [
                .copy("Test Documents")
            ]
        ),
        
        // Integration Tests
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Digester",
                "IrisSearch",
                "TestUtilities"
            ],
            resources: [
                .copy("Test Documents")
            ]
       )
    ]
)
