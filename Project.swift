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
            dependencies: []
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
    ]
)
