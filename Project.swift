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
                "Iris/Resources",
            ],
            scripts: [
                .post(
                    script: """
                    export PATH="$HOME/.local/bin:$PATH"
                    cd "$SRCROOT"
                    mise exec -- swiftlint lint --quiet --config .swiftlint.yml
                    """,
                    name: "SwiftLint",
                    basedOnDependencyAnalysis: false,
                ),
            ],
            dependencies: [
//                .external(name: "sentry")
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
