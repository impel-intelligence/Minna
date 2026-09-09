//
//  NoteGraphSimulationTests.swift
//  Minna
//
//  Created by Claude Fable 5 (Anthropic) on 2026-09-08.
//

@testable import Minna
import SwiftUI
import Testing

/// A tiny deterministic linear congruential generator so the fly-off stress test is reproducible run to run.
/// - Authored by: Claude Fable 5 (Anthropic)
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

@MainActor
struct NoteGraphSimulationTests {
    /// Builds a paused simulation and places nodes at exact positions, bypassing the random spawn jitter.
    /// - Authored by: Claude Fable 5 (Anthropic)
    private func makeSimulation(positions: [CGPoint], center: CGPoint = CGPoint(x: 500, y: 400)) -> (NoteGraphSimulation, [UUID]) {
        let simulation = NoteGraphSimulation(autostart: false)
        simulation.center = center
        var ids: [UUID] = []
        for position in positions {
            let id = UUID()
            simulation.upsertNode(id: id, spawnNear: position)
            simulation.nodes[id]?.position = position
            simulation.nodes[id]?.size = CGSize(width: 200, height: 100)
            ids.append(id)
        }
        return (simulation, ids)
    }

    private func stepMany(_ simulation: NoteGraphSimulation, _ count: Int) {
        for _ in 0..<count { simulation.step() }
    }

    @Test func connectedNotesPullTogether() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 0, y: 400), CGPoint(x: 1000, y: 400)])
        simulation.setEdges([NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1)])

        let initialDistance = simulation.nodes[ids[0]]!.position.distance(to: simulation.nodes[ids[1]]!.position)
        stepMany(simulation, 1200)
        let finalDistance = simulation.nodes[ids[0]]!.position.distance(to: simulation.nodes[ids[1]]!.position)

        #expect(finalDistance < initialDistance, "Connected notes should move toward each other.")
        let restLength = simulation.nodes[ids[0]]!.effectiveRadius + simulation.nodes[ids[1]]!.effectiveRadius + simulation.parameters.springRestGap
        #expect(finalDistance < restLength * 2, "Connected notes should settle near the spring rest length, not remain far apart.")
    }

    @Test func unconnectedNotesRepel() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 480, y: 400), CGPoint(x: 520, y: 400)])
        simulation.parameters.collisionsEnabled = false

        let initialDistance = simulation.nodes[ids[0]]!.position.distance(to: simulation.nodes[ids[1]]!.position)
        stepMany(simulation, 600)
        let finalDistance = simulation.nodes[ids[0]]!.position.distance(to: simulation.nodes[ids[1]]!.position)

        #expect(finalDistance > initialDistance, "Unconnected notes should push apart.")
    }

    @Test func notesNeverFlyOffTheCanvas() {
        var generator = SeededGenerator(state: 42)
        let center = CGPoint(x: 500, y: 400)
        let positions = (0..<20).map { _ in
            CGPoint(x: .random(in: 0...1000, using: &generator), y: .random(in: 0...800, using: &generator))
        }
        let (simulation, ids) = makeSimulation(positions: positions, center: center)

        var edges: [NoteGraphSimulation.Edge] = []
        for i in 0..<ids.count {
            for j in (i + 1)..<ids.count where Double.random(in: 0...1, using: &generator) < 0.15 {
                edges.append(NoteGraphSimulation.Edge(a: ids[i], b: ids[j], weight: 1))
            }
        }
        simulation.setEdges(edges)

        // Check the bound periodically during the run, not just at the end, so a transient explosion can't hide behind later damping.
        for _ in 0..<30 {
            stepMany(simulation, 100)
            for node in simulation.nodes.values {
                #expect(node.position.distance(to: center) < 2_500, "A note left the working area around the center; the simulation is unstable.")
            }
        }
    }

    @Test func simulationReachesSteadyStateAndSleeps() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 0, y: 0), CGPoint(x: 900, y: 700), CGPoint(x: 100, y: 700)])
        simulation.setEdges([
            NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1),
            NoteGraphSimulation.Edge(a: ids[1], b: ids[2], weight: 1)
        ])

        stepMany(simulation, 3600)
        #expect(simulation.isSettled, "The simulation should find a steady state within 60 simulated seconds.")

        for node in simulation.nodes.values {
            #expect(node.velocity.magnitude == 0, "Velocities should be zeroed once the simulation sleeps.")
        }

        let frozenPositions = simulation.nodes.mapValues(\.position)
        stepMany(simulation, 60)
        for (id, position) in frozenPositions {
            #expect(simulation.nodes[id]?.position == position, "A settled simulation should not move notes.")
        }
    }

    @Test func draggingPinsTheNodeAndWakesTheSimulation() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 400, y: 400), CGPoint(x: 700, y: 400)])
        simulation.setEdges([NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1)])
        stepMany(simulation, 3600)
        #expect(simulation.isSettled)

        simulation.beginDrag(id: ids[0])
        #expect(!simulation.isSettled, "Starting a drag should wake the simulation.")

        simulation.drag(id: ids[0], by: CGSize(width: -300, height: -200))
        let draggedPosition = simulation.nodes[ids[0]]!.position
        stepMany(simulation, 120)
        #expect(simulation.nodes[ids[0]]!.position == draggedPosition, "The simulation must not move a note while the user is dragging it.")

        simulation.endDrag(id: ids[0])
        stepMany(simulation, 3600)
        #expect(simulation.isSettled, "The simulation should settle again after a drag ends.")
    }

    @Test func overlappingNotesAreSeparatedByCollisions() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 500, y: 400), CGPoint(x: 520, y: 410)])
        simulation.setEdges([NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1)])

        stepMany(simulation, 1200)

        let nodeA = simulation.nodes[ids[0]]!
        let nodeB = simulation.nodes[ids[1]]!
        let rectA = CGRect(origin: CGPoint(x: nodeA.position.x - nodeA.size.width / 2, y: nodeA.position.y - nodeA.size.height / 2), size: nodeA.size)
        let rectB = CGRect(origin: CGPoint(x: nodeB.position.x - nodeB.size.width / 2, y: nodeB.position.y - nodeB.size.height / 2), size: nodeB.size)
        #expect(!rectA.intersects(rectB), "Connected cards should pack next to each other, not stack on top of each other.")
    }

    @Test func clustersFollowConnectedComponents() {
        let (simulation, ids) = makeSimulation(positions: (0..<5).map { CGPoint(x: Double($0) * 300, y: 400) })
        simulation.setEdges([
            NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1),
            NoteGraphSimulation.Edge(a: ids[1], b: ids[2], weight: 1),
            NoteGraphSimulation.Edge(a: ids[3], b: ids[4], weight: 1)
        ])

        let clusterA = Set([ids[0], ids[1], ids[2]].map { simulation.nodes[$0]!.clusterIndex })
        let clusterB = Set([ids[3], ids[4]].map { simulation.nodes[$0]!.clusterIndex })
        #expect(clusterA.count == 1, "Notes in one connected component should share a cluster index.")
        #expect(clusterB.count == 1, "Notes in one connected component should share a cluster index.")
        #expect(clusterA != clusterB, "Separate components should have distinct cluster indices.")
    }

    @Test func largeNotesPullSmallNotesMoreThanTheReverse() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 100, y: 400), CGPoint(x: 900, y: 400)])
        simulation.nodes[ids[0]]!.size = CGSize(width: 400, height: 250)
        simulation.nodes[ids[1]]!.size = CGSize(width: 120, height: 60)
        simulation.setEdges([NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1)])
        // Zero out center gravity so the only pull in play is the spring between the pair.
        simulation.parameters.centerStrength = 0

        let startLarge = simulation.nodes[ids[0]]!.position
        let startSmall = simulation.nodes[ids[1]]!.position
        stepMany(simulation, 120)

        let largeDisplacement = simulation.nodes[ids[0]]!.position.distance(to: startLarge)
        let smallDisplacement = simulation.nodes[ids[1]]!.position.distance(to: startSmall)
        #expect(smallDisplacement > largeDisplacement * 2, "The small note should be pulled substantially farther than the large note moves.")
    }

    @Test func zeroMassInfluenceRestoresSymmetricMotion() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 100, y: 400), CGPoint(x: 900, y: 400)])
        simulation.nodes[ids[0]]!.size = CGSize(width: 400, height: 250)
        simulation.nodes[ids[1]]!.size = CGSize(width: 120, height: 60)
        simulation.setEdges([NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1)])
        simulation.parameters.centerStrength = 0
        simulation.parameters.massInfluence = 0

        #expect(simulation.mass(of: simulation.nodes[ids[0]]!) == 1)
        #expect(simulation.mass(of: simulation.nodes[ids[1]]!) == 1)

        let startLarge = simulation.nodes[ids[0]]!.position
        let startSmall = simulation.nodes[ids[1]]!.position
        stepMany(simulation, 120)

        let largeDisplacement = simulation.nodes[ids[0]]!.position.distance(to: startLarge)
        let smallDisplacement = simulation.nodes[ids[1]]!.position.distance(to: startSmall)
        #expect(abs(largeDisplacement - smallDisplacement) < 1, "With mass influence at 0, both notes should move toward each other equally.")
    }

    @Test func removingANodeDropsItsEdges() {
        let (simulation, ids) = makeSimulation(positions: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)])
        simulation.setEdges([NoteGraphSimulation.Edge(a: ids[0], b: ids[1], weight: 1)])

        simulation.removeNode(id: ids[0])
        #expect(simulation.nodes[ids[0]] == nil)
        #expect(simulation.edges.isEmpty, "Edges referencing a removed note should be removed with it.")
    }
}

/// Embeds text onto fixed axes by keyword so graph-model tests control exactly which notes count as related.
/// - Authored by: Claude Fable 5 (Anthropic)
private struct StubEmbedder: NoteEmbedder {
    func vector(for text: String) -> [Double]? {
        let topics = ["gibbon", "howler", "tarsier"]
        var vector = [Double](repeating: 0.0, count: topics.count)
        for (index, topic) in topics.enumerated() where text.localizedCaseInsensitiveContains(topic) {
            vector[index] = 1
        }
        return vector.contains(1) ? vector : nil
    }
}

@MainActor
struct NoteGraphModelTests {
    private let sections = [
        NoteBlock.Section(subject: "Gibbon songs", content: "Gibbons sing elaborate songs."),
        NoteBlock.Section(subject: "Gibbon duets", content: "Gibbon pairs coordinate their songs."),
        NoteBlock.Section(subject: "Howler calls", content: "Howler monkeys make loud calls.")
    ]

    @Test func syncConnectsOnlySimilarNotes() {
        let model = NoteGraphModel(embedder: StubEmbedder(), autostartSimulation: false)
        model.sync(sections: sections)

        #expect(model.simulation.nodes.count == 3)
        #expect(model.simulation.edges.count == 1, "Only the two gibbon notes are similar enough to connect.")

        let clusterIndices = Set(model.simulation.nodes.values.map(\.clusterIndex))
        #expect(clusterIndices.count == 2, "Gibbon notes and the howler note should form two clusters.")
    }

    @Test func syncRemovesDeletedSections() {
        let model = NoteGraphModel(embedder: StubEmbedder(), autostartSimulation: false)
        model.sync(sections: sections)
        model.sync(sections: Array(sections.prefix(1)))

        #expect(model.simulation.nodes.count == 1)
        #expect(model.simulation.edges.isEmpty)
    }

    @Test func thresholdChangeRebuildsEdges() {
        let model = NoteGraphModel(embedder: StubEmbedder(), autostartSimulation: false)
        model.sync(sections: sections)
        #expect(model.simulation.edges.count == 1)

        // Cosine distance between orthogonal topic vectors is 1, so a threshold above 1 connects everything.
        model.parameters.connectionThreshold = 1.2
        model.rebuildEdges()
        #expect(model.simulation.edges.count == 3, "Raising the threshold above the orthogonal distance should connect every pair.")

        model.parameters.connectionThreshold = 0.1
        model.rebuildEdges()
        #expect(model.simulation.edges.count == 1, "A near-zero threshold should keep only the identical gibbon pair connected.")
    }

    @Test func cosineDistanceBehaviors() {
        #expect(abs(NoteGraphModel.cosineDistance([1, 0], [1, 0])) < 0.0001)
        #expect(abs(NoteGraphModel.cosineDistance([1, 0], [0, 1]) - 1) < 0.0001)
        #expect(abs(NoteGraphModel.cosineDistance([1, 0], [-1, 0]) - 2) < 0.0001)
        #expect(NoteGraphModel.cosineDistance([1, 0], [0, 0]) == 2, "Degenerate vectors should never connect.")
        #expect(NoteGraphModel.cosineDistance([1, 0], [1, 0, 1]) == 2, "Mismatched dimensions should never connect.")
    }
}
