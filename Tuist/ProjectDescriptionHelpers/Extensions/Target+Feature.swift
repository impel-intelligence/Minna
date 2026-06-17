import ProjectDescription

public extension Target {
    static func microFeature(name: String, product: Product = .staticFramework, resources: ProjectDescription.ResourceFileElements? = nil, copyFiles: [ProjectDescription.CopyFilesAction]? = nil, headers: ProjectDescription.Headers? = nil, entitlements: ProjectDescription.Entitlements? = nil, scripts: [ProjectDescription.TargetScript] = [], dependencies: [ProjectDescription.TargetDependency] = [], settings: ProjectDescription.Settings? = nil, coreDataModels: [ProjectDescription.CoreDataModel] = [], environmentVariables: [String : ProjectDescription.EnvironmentVariable] = [:], launchArguments: [ProjectDescription.LaunchArgument] = [], additionalFiles: [ProjectDescription.FileElement] = [], buildRules: [ProjectDescription.BuildRule] = [], mergedBinaryType: ProjectDescription.MergedBinaryType = .disabled, mergeable: Bool = false, onDemandResourcesTags: ProjectDescription.OnDemandResourcesTags? = nil) -> Target {
        return .target(
            name: name,
            destinations: .macOS,
            product: product,
            bundleId: PRODUCT_BUNDLE_IDENTIFIER + "." + name,
            deploymentTargets: .macOS(TARGET_MACOS_VERSION),
            sources: ["Modules/Features/\(name)/Sources/**"],
            resources: resources,
            copyFiles: copyFiles,
            headers: headers,
            entitlements: entitlements,
            scripts: scripts,
            dependencies: dependencies,
            settings: settings,
            launchArguments: launchArguments,
            additionalFiles: additionalFiles,
            buildRules: buildRules,
            mergedBinaryType: mergedBinaryType,
            mergeable: mergeable,
            onDemandResourcesTags: onDemandResourcesTags
        )
    }
    
    static func microFeatureTests(name: String, resources: ProjectDescription.ResourceFileElements? = nil, copyFiles: [ProjectDescription.CopyFilesAction]? = nil, headers: ProjectDescription.Headers? = nil, entitlements: ProjectDescription.Entitlements? = nil, scripts: [ProjectDescription.TargetScript] = [], dependencies: [ProjectDescription.TargetDependency] = [], settings: ProjectDescription.Settings? = nil, coreDataModels: [ProjectDescription.CoreDataModel] = [], environmentVariables: [String : ProjectDescription.EnvironmentVariable] = [:], launchArguments: [ProjectDescription.LaunchArgument] = [], additionalFiles: [ProjectDescription.FileElement] = [], buildRules: [ProjectDescription.BuildRule] = [], mergedBinaryType: ProjectDescription.MergedBinaryType = .disabled, mergeable: Bool = false, onDemandResourcesTags: ProjectDescription.OnDemandResourcesTags? = nil) -> Target {
        var dependencies = dependencies
        
        let featureTarget: TargetDependency = .target(name: name)
        if !dependencies.contains(featureTarget) {
            dependencies.append(featureTarget)
        }
        
        if !dependencies.contains(.xctest) {
            dependencies.append(.xctest)
        }
        
        return .target(
            name: "\(name)Tests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: PRODUCT_BUNDLE_IDENTIFIER + "." + "\(name)Tests",
            deploymentTargets: .macOS(TARGET_MACOS_VERSION),
            sources: ["Modules/Features/\(name)/Tests/**"],
            resources: resources,
            copyFiles: copyFiles,
            headers: headers,
            entitlements: entitlements,
            scripts: scripts,
            dependencies: dependencies,
            settings: settings,
            launchArguments: launchArguments,
            additionalFiles: additionalFiles,
            buildRules: buildRules,
            mergedBinaryType: mergedBinaryType,
            mergeable: mergeable,
            onDemandResourcesTags: onDemandResourcesTags
        )
    }
    
}
