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
            infoPlist: irisInfoPlist,
            buildableFolders: [
                "Iris/Sources",
                "Iris/Resources"
            ],
            scripts: [
                .post(
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
                .external(name: "SFSymbols"),
                .external(name: "ViewStorage"),
                .external(name: "IrisSearch"),
                .external(name: "Digester"),
                .external(name: "BlurbKit"),
                .external(name: "OrderedCollections")
            ],
            settings: irisSettings
        ),
        .target(
            name: "IrisTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.tryiris.iris.mac.tests",
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
