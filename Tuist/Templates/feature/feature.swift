import ProjectDescription

let featureNameAttribute: Template.Attribute = .required("name")

let featureTemplate = Template(
    description: "Feature Template",
    attributes: [
        featureNameAttribute,
        .optional("platform", default: "macOS"),
    ],
    items: [
        .string(
            path: "Modules/Features/\(featureNameAttribute)/Sources/\(featureNameAttribute).swift",
            contents: """
            // Iris µFeature: \(featureNameAttribute) Source
            """
        ),
        .string(
            path: "Modules/Features/\(featureNameAttribute)/Tests/\(featureNameAttribute)Tests.swift",
            contents: """
            // Iris µFeature: \(featureNameAttribute) Tests
            
            @testable import \(featureNameAttribute)
            import Testing
            
            struct \(featureNameAttribute)Tests {
                
            }
            """
        ),
        .string(
            path: "Modules/Features/\(featureNameAttribute)/README.md",
            contents: """
            # Iris µFeature: \(featureNameAttribute)
            """
        )
    ]
)
