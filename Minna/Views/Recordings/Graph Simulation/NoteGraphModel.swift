//
//  NoteGraphModel.swift
//  Minna
//
//  Created by Claude Fable 5 (Anthropic) on 2026-09-08.
//

import SwiftUI
import NaturalLanguage
import Accelerate

/// Anything that can turn a note's text into an embedding vector. Abstracted so previews can supply deterministic vectors without loading NLEmbedding assets.
/// - Authored by: Claude Fable 5 (Anthropic)
protocol NoteEmbedder {
    func vector(for text: String) -> [Double]?
}

/// Embeds note text with Apple's on-device sentence embedding from the NaturalLanguage framework.
/// - Authored by: Claude Fable 5 (Anthropic)
struct SentenceEmbedder: NoteEmbedder {
    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)

    func vector(for text: String) -> [Double]? {
        embedding?.vector(for: text)
    }
}

/// Bridges `NoteTaker` sections into the force simulation: it owns node identity, computes an embedding per note, and connects any two notes whose embedding cosine distance is under the adjustable threshold.
/// - Authored by: Claude Fable 5 (Anthropic)
@MainActor @Observable
final class NoteGraphModel {
    let simulation: NoteGraphSimulation
    var parameters: SimulationParameters { simulation.parameters }

    private let embedder: any NoteEmbedder
    private(set) var sectionsByID: [UUID: NoteBlock.Section] = [:]
    private var idsBySubject: [String: UUID] = [:]
    private var vectors: [UUID: [Double]] = [:]

    /// Palette used to tint connected clusters.
    static let clusterPalette: [Color] = [.blue, .teal, .orange, .pink, .purple, .green, .indigo, .brown, .cyan, .mint]

    /// - Parameter autostartSimulation: Forwarded to `NoteGraphSimulation`; tests pass false to step the physics manually.
    init(embedder: any NoteEmbedder = SentenceEmbedder(), autostartSimulation: Bool = true) {
        self.embedder = embedder
        self.simulation = NoteGraphSimulation(autostart: autostartSimulation)
    }

    func color(forCluster index: Int) -> Color {
        Self.clusterPalette[index % Self.clusterPalette.count]
    }

    /// Diffs the note taker's sections against the graph: new subjects spawn a node near the canvas center, changed content is re-embedded, and removed subjects drop their node. Finishes by rebuilding the edge set.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func sync(sections: [NoteBlock.Section]) {
        var seen: Set<UUID> = []

        for section in sections {
            let id: UUID
            if let existing = idsBySubject[section.subject] {
                id = existing
                if sectionsByID[id] != section {
                    vectors[id] = embedder.vector(for: embeddingText(for: section))
                }
            } else {
                id = UUID()
                idsBySubject[section.subject] = id
                simulation.upsertNode(id: id, spawnNear: simulation.center)
                vectors[id] = embedder.vector(for: embeddingText(for: section))
            }
            sectionsByID[id] = section
            seen.insert(id)
        }

        for (subject, id) in idsBySubject where !seen.contains(id) {
            idsBySubject[subject] = nil
            sectionsByID[id] = nil
            vectors[id] = nil
            simulation.removeNode(id: id)
        }

        rebuildEdges()
    }

    /// Recomputes which notes are connected from the stored vectors and the current connection threshold. Cheap for the tens of notes a session produces, so it is safe to call from a slider.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func rebuildEdges() {
        let ids = Array(sectionsByID.keys)
        var edges: [NoteGraphSimulation.Edge] = []

        for i in 0..<ids.count {
            guard let vectorA = vectors[ids[i]] else { continue }
            for j in (i + 1)..<ids.count {
                guard let vectorB = vectors[ids[j]] else { continue }
                guard let distance = Self.cosineDistance(vectorA, vectorB) else { continue }
                
                if distance < parameters.connectionThreshold {
                    edges.append(NoteGraphSimulation.Edge(a: ids[i], b: ids[j], weight: 1 - distance))
                }
            }
        }

        simulation.setEdges(edges)
    }

    private func embeddingText(for section: NoteBlock.Section) -> String {
        "\(section.subject). \(section.content)"
    }

    /// Cosine distance between vectorA and vectorB;
    /// https://rudrank.com/exploring-ai-cosine-similarity-rag-accelerate-swift
    ///
    /// - Returns: 0 means identical direction, nil when either vector is bad.
    static func cosineDistance(_ vectorA: [Double], _ vectorB: [Double]) -> Double? {
        guard vectorA.count == vectorB.count, !vectorA.isEmpty else { return nil }
        
        let count = vDSP_Length(vectorA.count)
        
        // Calculate dot product (A·B)
        var dotProduct: Double = 0.0
        vDSP_dotprD(vectorA, 1, vectorB, 1, &dotProduct, count)
        
        
        // Calculate magnitudes (||A|| and ||B||)
        var magnitudeA: Double = 0.0
        var magnitudeB: Double = 0.0
        
        vDSP_svesqD(vectorA, 1, &magnitudeA, count)
        vDSP_svesqD(vectorB, 1, &magnitudeB, count)
        
        // Compute final magnitudes
        magnitudeA = sqrt(magnitudeA)
        magnitudeB = sqrt(magnitudeB)
        
        // Check for zero vectors
        guard magnitudeA > Double.ulpOfOne && magnitudeB > Double.ulpOfOne else { return nil }
        
        
        // Calculate similarity
        let similarity = dotProduct / (magnitudeA * magnitudeB)

        // Handle potential numerical instability
        guard similarity.isFinite else { return nil }

        // Clamp result to [-1, 1] to handle floating-point precision issues
        return min(max(similarity, -1), 1)
    }
}
