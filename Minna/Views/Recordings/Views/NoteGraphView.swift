//
//  NoteGraphView.swift
//  Minna
//
//  Created by Claude Fable 5 (Anthropic) on 2026-09-08.
//

import SwiftUI

/// Renders the simulated note graph inside `CanvasView`. The infinite grid only offsets its children by the pan translation, so this view mirrors `DraggableView`'s convention: every world coordinate is multiplied by the canvas scale and card content is scaled with `scaleEffect`.
/// - Authored by: Claude Fable 5 (Anthropic)
struct NoteGraphView: View {
    var model: NoteGraphModel
    @Binding var scale: CGFloat

    var body: some View {
        if model.parameters.showsConnections {
            connectionLines
        }
        ForEach(Array(model.simulation.nodes.values)) { node in
            if let section = model.sectionsByID[node.id] {
                NoteGraphCard(model: model, node: node, section: section, scale: $scale)
            }
        }
    }

    /// Springs drawn as faint lines between connected cards, like Obsidian's graph view. The path uses scaled world coordinates directly; points outside the path view's own frame still draw because nothing clips it.
    private var connectionLines: some View {
        Path { path in
            for edge in model.simulation.edges {
                guard let from = model.simulation.nodes[edge.a], let to = model.simulation.nodes[edge.b] else { continue }
                path.move(to: from.position * scale)
                path.addLine(to: to.position * scale)
            }
        }
        .stroke(.primary.opacity(0.15), lineWidth: 1.5 * scale)
    }
}

/// A single note card in the graph: displays the section, reports its measured size to the simulation, glows with its cluster's color, and can be dragged. Dragging pins the node so the simulation pushes neighbors around it instead of fighting the user.
/// - Authored by: Claude Fable 5 (Anthropic)
struct NoteGraphCard: View {
    var model: NoteGraphModel
    var node: NoteGraphSimulation.Node
    let section: NoteBlock.Section
    @Binding var scale: CGFloat

    @State private var previousFrameTranslation: CGSize = .zero

    var body: some View {
        NoteSectionView(section: section)
            .glow(color: model.color(forCluster: node.clusterIndex).opacity(0.35), radius: 10)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                model.simulation.updateSize(id: node.id, size: size)
            }
            .scaleEffect(CGSize(width: scale, height: scale))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if !node.isDragging {
                            model.simulation.beginDrag(id: node.id)
                        }
                        let delta = value.translation - previousFrameTranslation
                        model.simulation.drag(id: node.id, by: delta / scale)
                        previousFrameTranslation = value.translation
                    }
                    .onEnded { _ in
                        previousFrameTranslation = .zero
                        model.simulation.endDrag(id: node.id)
                    }
            )
            .position(node.position * scale)
    }
}

/// Deterministic embedder for previews: notes sharing a keyword land on the same axis, so the preview forms predictable clusters without loading NLEmbedding assets.
/// - Authored by: Claude Fable 5 (Anthropic)
private struct KeywordStubEmbedder: NoteEmbedder {
    let topics = ["gibbon", "howler", "tarsier"]

    func vector(for text: String) -> [Double]? {
        var vector = [Double](repeating: 0.05, count: topics.count)
        for (index, topic) in topics.enumerated() where text.localizedCaseInsensitiveContains(topic) {
            vector[index] = 1
        }
        return vector
    }
}

#Preview {
    @Previewable @State var model = NoteGraphModel(embedder: KeywordStubEmbedder())
    @Previewable @State var translation: CGPoint = .zero
    @Previewable @State var scale: CGFloat = 1

    CanvasView(translation: $translation, scale: $scale) {
        NoteGraphView(model: model, scale: $scale)
    }
    .overlay(alignment: .trailing) {
        SimulationControlsView(model: model)
            .padding(10)
    }
    .frame(width: 1000, height: 700)
    .onAppear {
        model.simulation.center = CGPoint(x: 500, y: 350)
        model.sync(sections: [
            NoteBlock.Section(subject: "Gibbon songs", content: "Gibbons are known for their elaborate and melodious songs."),
            NoteBlock.Section(subject: "Gibbon song coordination", content: "Gibbon duets reflect coordination and strengthen social ties."),
            NoteBlock.Section(subject: "Gibbon vocal tracts", content: "Elongated gibbon vocal tracts create harmonics for territorial display."),
            NoteBlock.Section(subject: "Howler monkey hyoid bone", content: "Howler monkeys produce loud calls thanks to their specialized hyoid bone."),
            NoteBlock.Section(subject: "Howler forest adaptation", content: "Howler calls travel great distances through dense forest habitats."),
            NoteBlock.Section(subject: "Tarsier ultrasound", content: "Tarsiers use ultrasonic communication beyond human hearing."),
            NoteBlock.Section(subject: "Tarsier social signals", content: "Tarsier ultrasonic calls carry social signals between individuals.")
        ])
    }
}
