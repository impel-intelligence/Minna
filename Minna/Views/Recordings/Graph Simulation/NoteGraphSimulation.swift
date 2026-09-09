//
//  NoteGraphSimulation.swift
//  Minna
//
//  Created by Claude Fable 5 (Anthropic) on 2026-09-08.
//

import SwiftUI

/// A force-directed layout engine for note cards, inspired by Obsidian's graph view. Connected notes are joined by springs, all notes repel each other, and a weak center gravity keeps the whole graph on screen. The simulation runs at a fixed 60 Hz timestep and goes to sleep once every node settles, waking on any mutation, drag, or parameter change.
/// - Authored by: Claude Fable 5 (Anthropic)
@MainActor @Observable
final class NoteGraphSimulation {
    /// One body in the simulation. Position and size are in world (unscaled canvas) coordinates, with position at the card's center.
    /// - Authored by: Claude Fable 5 (Anthropic)
    @Observable
    final class Node: Identifiable {
        let id: UUID
        var position: CGPoint
        var velocity: CGVector = .zero
        var size: CGSize
        /// Set while the user drags this card; a dragged node exerts forces on its neighbors but is not moved by the simulation.
        var isDragging: Bool = false
        /// Index of the connected component this node belongs to, used to tint clusters consistently.
        var clusterIndex: Int = 0

        /// Distance from the card's center to its edge along a unit direction. Springs and repulsion use this instead of a circular radius: a wide card is "bigger" toward a horizontal neighbor than a vertical one, so rest distances never demand that two rectangles overlap — which previously kept the collision resolver firing every frame and made touching notes creep across the canvas.
        /// - Authored by: Claude Fable 5 (Anthropic)
        func extent(along unit: CGPoint) -> CGFloat {
            let absX = abs(unit.x)
            let absY = abs(unit.y)
            let toVerticalEdge = absX > 0.0001 ? size.width / (2 * absX) : .greatestFiniteMagnitude
            let toHorizontalEdge = absY > 0.0001 ? size.height / (2 * absY) : .greatestFiniteMagnitude
            return min(toVerticalEdge, toHorizontalEdge)
        }

        init(id: UUID, position: CGPoint, size: CGSize = CGSize(width: 250, height: 100)) {
            self.id = id
            self.position = position
            self.size = size
        }
    }

    /// An undirected spring between two related notes. Weight is the embedding similarity (1 - cosine distance), reserved for scaling spring strength.
    struct Edge: Hashable {
        let a: UUID
        let b: UUID
        let weight: Double
    }

    private(set) var nodes: [UUID: Node] = [:]
    private(set) var edges: [Edge] = []
    let parameters: SimulationParameters
    /// The world-space point that center gravity pulls toward. Set by the hosting view to the visible center of the canvas.
    var center: CGPoint = .zero

    /// True once every node has been at rest long enough that stepping is skipped. Exposed so the UI can show simulation state.
    private(set) var isSettled: Bool = false
    private var quietFrames: Int = 0

    private let timeStep: Double = 1.0 / 60.0

    /// - Parameter autostart: When false the 60 Hz stepping loop is not started, letting tests drive the simulation deterministically by calling `step()` themselves.
    init(parameters: SimulationParameters = SimulationParameters(), autostart: Bool = true) {
        self.parameters = parameters
        guard autostart else { return }
        // The loop holds self weakly, so it ends on its own when the simulation is deallocated — no deinit cancellation needed, and no retain cycle.
        Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16.67))
                guard let self else { break }
                self.step()
            }
        }
    }

    // MARK: - Mutations

    /// Adds a node, or updates the size of an existing one, and wakes the simulation.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func upsertNode(id: UUID, spawnNear point: CGPoint) {
        guard nodes[id] == nil else { return }
        let jitter = CGPoint(x: point.x + .random(in: -120...120), y: point.y + .random(in: -120...120))
        nodes[id] = Node(id: id, position: jitter)
        wake()
    }

    func removeNode(id: UUID) {
        nodes[id] = nil
        edges.removeAll { $0.a == id || $0.b == id }
        wake()
    }

    /// Replaces the edge set (typically after embeddings or the connection threshold change) and reassigns cluster indices from the new connectivity.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func setEdges(_ newEdges: [Edge]) {
        edges = newEdges.filter { nodes[$0.a] != nil && nodes[$0.b] != nil }
        assignClusters()
        wake()
    }

    /// Reports the measured on-screen size of a card so forces and collisions use real dimensions.
    func updateSize(id: UUID, size: CGSize) {
        guard let node = nodes[id], node.size != size else { return }
        node.size = size
        wake()
    }

    // MARK: - Dragging

    func beginDrag(id: UUID) {
        guard let node = nodes[id] else { return }
        node.isDragging = true
        node.velocity = .zero
        wake()
    }

    func drag(id: UUID, by delta: CGSize) {
        guard let node = nodes[id] else { return }
        node.position = node.position.translate(by: delta)
        wake()
    }

    func endDrag(id: UUID) {
        guard let node = nodes[id] else { return }
        node.isDragging = false
        node.velocity = .zero
        wake()
    }

    /// Clears the settled state so the simulation resumes stepping. Call after any change that should re-run the layout.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func wake() {
        quietFrames = 0
        isSettled = false
    }

    // MARK: - Simulation

    /// Advances the simulation by one fixed timestep. Internal so tests can step deterministically; the app drives this from the built-in loop.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func step() {
        guard !isSettled, !nodes.isEmpty else { return }

        let bodies = Array(nodes.values)
        var forces: [UUID: CGVector] = [:]
        forces.reserveCapacity(bodies.count)
        var masses: [UUID: Double] = [:]
        masses.reserveCapacity(bodies.count)
        for body in bodies { masses[body.id] = mass(of: body) }

        // Springs pull connected notes toward a rest distance instead of an inverse-square attraction, which explodes at close range and launched notes off the canvas in the previous implementation. The force scales with the product of the two masses, gravity-style: since each node's acceleration divides by its own mass below, a large note pulls a small note hard while barely moving itself, and the equilibrium distance is unchanged.
        for edge in edges {
            guard let bodyA = nodes[edge.a], let bodyB = nodes[edge.b] else { continue }
            let distance = max(bodyA.position.distance(to: bodyB.position), 1)
            let unit = (bodyB.position - bodyA.position) / distance
            let restLength = bodyA.extent(along: unit) + bodyB.extent(along: unit) + parameters.springRestGap
            let stretch = distance - restLength
            let magnitude = parameters.springStiffness * stretch * masses[edge.a]! * masses[edge.b]!

            forces[edge.a, default: .zero] += CGVector(dx: unit.x * magnitude, dy: unit.y * magnitude)
            forces[edge.b, default: .zero] += CGVector(dx: -unit.x * magnitude, dy: -unit.y * magnitude)
        }

        // All pairs repel, related or not; springs win for connected notes so clusters still form. The force uses the gap between card edges rather than center distance so large cards don't sit inside each other.
        for i in 0..<bodies.count {
            let bodyA = bodies[i]
            for j in (i + 1)..<bodies.count {
                let bodyB = bodies[j]
                let distance = max(bodyA.position.distance(to: bodyB.position), 1)
                let unit = (bodyA.position - bodyB.position) / distance
                let gap = max(distance - bodyA.extent(along: unit) - bodyB.extent(along: unit), 10)
                guard gap < parameters.repulsionRadius else { continue }

                let massProduct = masses[bodyA.id]! * masses[bodyB.id]!
                let magnitude = min(parameters.repulsionStrength * massProduct / (gap * gap), 4_000 * massProduct)

                forces[bodyA.id, default: .zero] += CGVector(dx: unit.x * magnitude, dy: unit.y * magnitude)
                forces[bodyB.id, default: .zero] += CGVector(dx: -unit.x * magnitude, dy: -unit.y * magnitude)
            }
        }

        // Weak center gravity: without it, disconnected clusters repel each other forever and eventually leave the visible canvas. Scaled by mass so it cancels below and every note falls toward the center equally, like real gravity.
        for body in bodies {
            let pull = (center - body.position) * (parameters.centerStrength * masses[body.id]!)
            forces[body.id, default: .zero] += CGVector(dx: pull.x, dy: pull.y)
        }

        // Semi-implicit Euler (acceleration = force / mass) with exponential damping and a speed clamp, so no single frame can move a note far enough to destabilize the system.
        let retention = exp(-parameters.damping * timeStep)
        var maxObservedSpeed: CGFloat = 0
        for body in bodies where !body.isDragging {
            let force = forces[body.id] ?? .zero
            let bodyMass = masses[body.id]!
            body.velocity.dx = (body.velocity.dx + force.dx / bodyMass * timeStep) * retention
            body.velocity.dy = (body.velocity.dy + force.dy / bodyMass * timeStep) * retention

            let speed = body.velocity.magnitude
            if speed > parameters.maxSpeed {
                let scale = parameters.maxSpeed / speed
                body.velocity.dx *= scale
                body.velocity.dy *= scale
            }

            body.position.x += body.velocity.dx * timeStep
            body.position.y += body.velocity.dy * timeStep
            maxObservedSpeed = max(maxObservedSpeed, min(speed, parameters.maxSpeed))
        }

        if parameters.collisionsEnabled {
            resolveCollisions(bodies: bodies, masses: masses)
        }

        // Sleep once everything has been slow for half a second; wake() clears this on any interaction.
        if maxObservedSpeed < parameters.sleepSpeed {
            quietFrames += 1
            if quietFrames > 30 {
                isSettled = true
                for body in bodies { body.velocity = .zero }
            }
        } else {
            quietFrames = 0
        }
    }

    /// A note's mass, derived from its card area relative to the default card size and raised to the adjustable `massInfluence` exponent. At influence 0 every note weighs exactly 1, restoring mass-free behavior.
    /// - Authored by: Claude Fable 5 (Anthropic)
    func mass(of node: Node) -> Double {
        let referenceArea: Double = 250 * 100
        let relativeArea = max((node.size.width * node.size.height) / referenceArea, 0.05)
        return pow(relativeArea, parameters.massInfluence)
    }

    /// Pushes overlapping cards apart along the axis of least overlap and kills their velocity on that axis, which lets touching cards pack tightly and settle instead of oscillating. The separation is split by inverse mass, so a heavy note shoves a light one out of the way rather than being displaced itself.
    /// - Authored by: Claude Fable 5 (Anthropic)
    private func resolveCollisions(bodies: [Node], masses: [UUID: Double]) {
        for i in 0..<bodies.count {
            let bodyA = bodies[i]
            for j in (i + 1)..<bodies.count {
                let bodyB = bodies[j]

                let rectA = CGRect(origin: CGPoint(x: bodyA.position.x - bodyA.size.width / 2, y: bodyA.position.y - bodyA.size.height / 2), size: bodyA.size)
                let rectB = CGRect(origin: CGPoint(x: bodyB.position.x - bodyB.size.width / 2, y: bodyB.position.y - bodyB.size.height / 2), size: bodyB.size)
                guard rectA.intersects(rectB) else { continue }

                let massA = masses[bodyA.id] ?? 1
                let massB = masses[bodyB.id] ?? 1
                let shareA = massB / (massA + massB)

                let overlapX = min(rectA.maxX, rectB.maxX) - max(rectA.minX, rectB.minX)
                let overlapY = min(rectA.maxY, rectB.maxY) - max(rectA.minY, rectB.minY)

                // Only zero velocity components moving into the contact; erasing separating motion too let repeated contacts ratchet a touching pair across the canvas.
                if overlapX < overlapY {
                    let direction: CGFloat = bodyA.position.x < bodyB.position.x ? -1 : 1
                    if !bodyA.isDragging { bodyA.position.x += direction * overlapX * shareA }
                    if !bodyB.isDragging { bodyB.position.x -= direction * overlapX * (1 - shareA) }
                    if bodyA.velocity.dx * direction < 0 { bodyA.velocity.dx = 0 }
                    if bodyB.velocity.dx * direction > 0 { bodyB.velocity.dx = 0 }
                } else {
                    let direction: CGFloat = bodyA.position.y < bodyB.position.y ? -1 : 1
                    if !bodyA.isDragging { bodyA.position.y += direction * overlapY * shareA }
                    if !bodyB.isDragging { bodyB.position.y -= direction * overlapY * (1 - shareA) }
                    if bodyA.velocity.dy * direction < 0 { bodyA.velocity.dy = 0 }
                    if bodyB.velocity.dy * direction > 0 { bodyB.velocity.dy = 0 }
                }
            }
        }
    }

    /// Assigns each connected component a stable index via union-find so the UI can tint clusters.
    /// - Authored by: Claude Fable 5 (Anthropic)
    private func assignClusters() {
        var parent: [UUID: UUID] = [:]
        for id in nodes.keys { parent[id] = id }

        func find(_ id: UUID) -> UUID {
            var root = id
            while let next = parent[root], next != root { root = next }
            var current = id
            while let next = parent[current], next != root {
                parent[current] = root
                current = next
            }
            return root
        }

        for edge in edges {
            let rootA = find(edge.a)
            let rootB = find(edge.b)
            if rootA != rootB { parent[rootA] = rootB }
        }

        var clusterIndices: [UUID: Int] = [:]
        for id in nodes.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            let root = find(id)
            if clusterIndices[root] == nil {
                clusterIndices[root] = clusterIndices.count
            }
            nodes[id]?.clusterIndex = clusterIndices[root] ?? 0
        }
    }
}
