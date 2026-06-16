//
//  Database.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftData
import Foundation

@MainActor
class SampleDatabase {
    /// A struct that holds data to be populated into files during sample population.
    struct SampleFile {
        var createdAt: Date
        var title: String
        var shortDescription: String
        var color: ThemeColor
        var url: URL
        var source: String
        var type: ContentType
    }
    
    static let shared = SampleDatabase()
        
    public var sampleFolders: [Folder] = [
        Folder(name: "Unfilled", icon: FolderIcon(symbol: .symbol("tray.full")), files: [
            
        ], protected: true),
        Folder(name: "Coding", icon: FolderIcon(symbol: .symbol("ellipsis.curlybraces")), children: [
            Folder(name: "Firmware", icon: FolderIcon(symbol: .symbol("car")))
        ]),
        Folder(name: "Research Papers", icon: FolderIcon(symbol: .symbol("graduationcap")), children: [
            Folder(name: "Thesis", icon: FolderIcon(symbol: .symbol("pencil.line")))
        ])
    ]
    
    public var sampleFiles: [File] = []
    
    private var sampleFileData: [SampleFile] = [
        SampleFile(
            createdAt: Date().addingTimeInterval(60*60*1),
            title: "Syllabus Discussion",
            shortDescription: "A discussion about course requirements and syllabus details.",
            color: .random,
            url: URL(string: "https://example.com/images/api-architecture.png")!,
            source: "ask iris",
            type: .askIris
        ),

        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*1),
            title: "Project Kickoff Recording",
            shortDescription: "Initial meeting discussing goals and milestones.",
            color: .random,
            url: URL(string: "https://example.com/recordings/kickoff.mp3")!,
            source: "Team Drive",
            type: .recording
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*5),
            title: "API Architecture Diagram",
            shortDescription: "High-level microservice layout and data flow.",
            color: .random,
            url: URL(string: "https://example.com/images/api-architecture.png")!,
            source: "Design System",
            type: .image
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*12),
            title: "Swift Concurrency Cheatsheet",
            shortDescription: "Quick reference for async/await patterns.",
            color: .random,
            url: URL(string: "iris://internal/notes/swift-concurrency")!,
            source: "Internal Notes",
            type: .webpage
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*18),
            title: "Apple Developer - SwiftData Overview",
            shortDescription: "Official docs for modeling and persistence.",
            color: .random,
            url: URL(string: "https://developer.apple.com/documentation/swiftdata")!,
            source: "Apple Developer",
            type: .webpage
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*24),
            title: "User Research Recording - Onboarding",
            shortDescription: "Interview with first-time users.",
            color: .random,
            url: URL(string: "https://media.example.org/research/onboarding-session.m4a")!,
            source: "Research Vault",
            type: .recording
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*30),
            title: "Firmware Pinout Reference",
            shortDescription: "GPIO and power layout photo.",
            color: .random,
            url: URL(string: "https://cdn.example.net/hw/pinout.jpg")!,
            source: "Hardware Wiki",
            type: .image
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*36),
            title: "Design Tokens Spec",
            shortDescription: "Internal token naming conventions.",
            color: .random,
            url: URL(string: "iris://internal/specs/design-tokens")!,
            source: "Design System",
            type: .text
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*42),
            title: "Swift Forums - Actors Best Practices",
            shortDescription: "Community guidance on actor isolation.",
            color: .random,
            url: URL(string: "https://forums.swift.org/t/best-practices-for-actors/")!,
            source: "Swift Forums",
            type: .pdf
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*48),
            title: "Synthesis Recording - Sprint 12",
            shortDescription: "Wrap-up of sprint outcomes and learnings.",
            color: .random,
            url: URL(string: "https://example.com/recordings/sprint12.m4a")!,
            source: "Team Drive",
            type: .recording
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*54),
            title: "Crash Graph Screenshot",
            shortDescription: "Top crash trends last 7 days.",
            color: .random,
            url: URL(string: "https://analytics.example.com/images/crash-graph.png")!,
            source: "Analytics",
            type: .image
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*60),
            title: "Thesis Outline",
            shortDescription: "Internal outline for research thesis.",
            color: .random,
            url: URL(string: "iris://internal/research/thesis-outline")!,
            source: "Research Notes",
            type: .text
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*66),
            title: "NLP Paper - Transformers",
            shortDescription: "Seminal paper on attention mechanisms.",
            color: .random,
            url: URL(string: "https://arxiv.org/abs/1706.03762")!,
            source: "arXiv",
            type: .pdf
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*72),
            title: "Standup Recording 06-10",
            shortDescription: "Daily updates and blockers.",
            color: .random,
            url: URL(string: "https://media.example.org/standups/2026-06-10.m4a")!,
            source: "Team Drive",
            type: .recording
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*78),
            title: "Wireframe Snapshot",
            shortDescription: "Iteration 2 of onboarding flow.",
            color: .random,
            url: URL(string: "https://design.example.com/wireframes/onboarding-v2.png")!,
            source: "Figma Export",
            type: .image
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*84),
            title: "Release",
            shortDescription: "Internal QA and store submission discussion.",
            color: .random,
            url: URL(string: "iris://internal/process/release-checklist")!,
            source: "Ops Wiki",
            type: .video
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*90),
            title: "HIG - Human Interface Guidelines",
            shortDescription: "Design guidance for Apple platforms.",
            color: .random,
            url: URL(string: "https://developer.apple.com/design/human-interface-guidelines/")!,
            source: "Apple Developer",
            type: .webpage
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*96),
            title: "Retrospective Recording",
            shortDescription: "Team reflections and action items.",
            color: .random,
            url: URL(string: "https://example.com/recordings/retro-06-01.m4a")!,
            source: "Team Drive",
            type: .recording
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*102),
            title: "Benchmark Chart Image",
            shortDescription: "Performance results for v1.3.",
            color: .random,
            url: URL(string: "https://cdn.example.net/benchmarks/v1_3.png")!,
            source: "CI Dashboard",
            type: .image
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*108),
            title: "Incident Postmortem",
            shortDescription: "Root cause and remediation steps.",
            color: .random,
            url: URL(string: "iris://internal/incidents/2026-05-27")!,
            source: "Ops Wiki",
            type: .webpage
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*114),
            title: "WebKit Blog - Performance Tips",
            shortDescription: "Optimizing web content rendering.",
            color: .random,
            url: URL(string: "https://webkit.org/blog/")!,
            source: "WebKit Blog",
            type: .webpage
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*120),
            title: "Prototype Demo Recording",
            shortDescription: "Clickable prototype walkthrough.",
            color: .random,
            url: URL(string: "https://media.example.org/demos/prototype-v0.m4a")!,
            source: "Design Team",
            type: .recording
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*126),
            title: "Sensor Calibration Photo",
            shortDescription: "Calibration jig alignment reference.",
            color: .random,
            url: URL(string: "https://hw.example.com/calibration/jig.jpg")!,
            source: "Hardware Lab",
            type: .image
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*132),
            title: "Team Directory",
            shortDescription: "Internal contact list and roles.",
            color: .random,
            url: URL(string: "iris://internal/people/team-directory")!,
            source: "HR Portal",
            type: .webpage
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*138),
            title: "Apple Security - Secure Enclave",
            shortDescription: "Overview of Secure Enclave technology.",
            color: .random,
            url: URL(string: "https://support.apple.com/guide/security/welcome/web")!,
            source: "Apple Support",
            type: .webpage
        ),
        SampleFile(
            createdAt: Date().addingTimeInterval(-60*60*144),
            title: "All-hands Recording",
            shortDescription: "Company updates from leadership.",
            color: .random,
            url: URL(string: "https://example.com/recordings/allhands-2026-06.m4a")!,
            source: "Company Comms",
            type: .recording
        )
    ]
            
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    private init(sampleData: Bool = false) {
        let schema = Schema([
            File.self,
            Folder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try populateSampleData()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func populateSampleData() throws {
        for folder in sampleFolders {
            context.insert(folder)
            
            for (index, sampleFile) in sampleFileData.enumerated() {
                let file = File(createdAt: sampleFile.createdAt, folder: folder, title: sampleFile.title, shortDescription: sampleFile.shortDescription, color: sampleFile.color, type: sampleFile.type, url: sampleFile.url, bookmark: nil, source: sampleFile.source, order: index)
                sampleFiles.append(file)
                context.insert(file)
            }
        }
    }
}
