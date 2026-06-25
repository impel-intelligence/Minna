import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Minna",
    settings: .settings(
        base: SettingsDictionary().automaticCodeSigning(devTeam: DEV_TEAM)
    ),
    targets: [
        .target(
            name: "Minna",
            destinations: .macOS,
            product: .app,
            bundleId: PRODUCT_BUNDLE_IDENTIFIER,
            deploymentTargets: DeploymentTargets.multiplatform(macOS: TARGET_MACOS_VERSION),
            infoPlist: minnaInfoPlist,
            buildableFolders: [
                "Minna/Sources",
                "Minna/Resources"
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
                .external(name: "SentrySPM"),
                .external(name: "Sparkle")
            ],
            settings: minnaSettings
        ),
        .target(
            name: "MinnaTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "\(PRODUCT_BUNDLE_IDENTIFIER).tests",
            deploymentTargets: DeploymentTargets.multiplatform(macOS: TARGET_MACOS_VERSION),
            infoPlist: .default,
            buildableFolders: [
                "Minna/Tests"
            ],
            dependencies: [.target(name: "Iris")],
            settings: minnaTestSettings
        ),
        .target(
            name: "MinnaUITests",
            destinations: .macOS,
            product: .uiTests,
            bundleId: "\(PRODUCT_BUNDLE_IDENTIFIER).uitests",
            deploymentTargets: DeploymentTargets.multiplatform(macOS: TARGET_MACOS_VERSION),
            infoPlist: .default,
            buildableFolders: [
                "Minna/UITests"
            ],
            dependencies: [.target(name: "Iris")],
            settings: minnaTestSettings
        ),

        // MARK: Features

        // MARK: Services

    ]
)
