import ProjectDescription

let serviceNameAttribute: Template.Attribute = .required("name")

let serviceTemplate = Template(
    description: "Service Template",
    attributes: [
        serviceNameAttribute,
        .optional("platform", default: "macOS"),
    ],
    items: [
        .string(
            path: "Modules/Services/\(serviceNameAttribute)/Sources/\(serviceNameAttribute).swift",
            contents: """
            // Iris µService: \(serviceNameAttribute) Source
            """
        ),
        .string(
            path: "Modules/Services/\(serviceNameAttribute)/Tests/\(serviceNameAttribute)Tests.swift",
            contents: """
            // Iris µService: \(serviceNameAttribute) Tests
            
            @testable import \(serviceNameAttribute)
            import Testing
            
            struct \(serviceNameAttribute)Tests {
                
            }
            """
        ),
        .string(
            path: "Modules/Services/\(serviceNameAttribute)/README.md",
            contents: """
            # Iris µService: \(serviceNameAttribute)
            """
        )
    ]
)
