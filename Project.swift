import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Iris",
    targets: [
        .target(
            name: "Iris",
            destinations: .macOS,
            product: .app,
            bundleId: "com.tryiris.iris.mac",
            deploymentTargets: DeploymentTargets.multiplatform(macOS: TARGET_MACOS_VERSION),
            infoPlist: irisInfoPlist,
            buildableFolders: [
                "Iris/Sources",
                "Iris/Resources"
            ],
            scripts: [
                .pre(
                    script: """
                    export PATH="$HOME/.local/bin:$PATH"
                    cd "$SRCROOT"
                    mise exec -- swiftlint lint --quiet --config .swiftlint.yml
                    """,
                    name: "SwiftLint",
                    inputPaths: [
                        "mise.toml",
                        ".swiftlint.yml"
                    ],
                    basedOnDependencyAnalysis: false,
                )
            ],
            dependencies: [
                .external(name: "SFSafeSymbols"),
                .external(name: "ViewStorage"),
                .external(name: "IrisSearch"),
                .external(name: "Digester"),
                .external(name: "BlurbKit"),
                .external(name: "Collections"),
                .external(name: "Sentry"),
                .external(name: "Sparkle")
            ],
            settings: irisSettings
        ),
        .target(
            name: "IrisTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.tryiris.iris.mac.tests",
            deploymentTargets: DeploymentTargets.multiplatform(macOS: TARGET_MACOS_VERSION),
            infoPlist: .default,
            buildableFolders: [
                "Iris/Tests"
            ],
            dependencies: [.target(name: "Iris")]
        ),
        .target(
            name: "IrisUITests",
            destinations: .macOS,
            product: .uiTests,
            bundleId: "com.tryiris.iris.mac.uitests",
            deploymentTargets: DeploymentTargets.multiplatform(macOS: TARGET_MACOS_VERSION),
            infoPlist: .default,
            buildableFolders: [
                "Iris/UITests"
            ],
            dependencies: [.target(name: "Iris")]
        ),
        
        // MARK: Features
        
        // MARK: Services

    ]
)
