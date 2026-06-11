import ProjectDescription

let project = Project(
    name: "Iris",
    targets: [
        .target(
            name: "Iris",
            destinations: .macOS,
            product: .app,
            bundleId: "com.tryiris.iris.mac",
            infoPlist: .default,
            buildableFolders: [
                "Iris/Sources",
                "Iris/Resources",
            ],
            scripts: [
                .pre(
                    script: """
                    export PATH="$HOME/.local/bin:$PATH"
                    cd "$SRCROOT"
                    mise exec -- swiftlint lint --quiet
                    """,
                    name: "SwiftLint",
                    basedOnDependencyAnalysis: false
                ),
            ]
        ),
        .target(
            name: "IrisTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.tryiris.iris.mac.tests",
            infoPlist: .default,
            buildableFolders: [
                "Iris/Tests",
            ],
            dependencies: [.target(name: "Iris")]
        ),
    ]
)
