//
//  SimulationControlsView.swift
//  Minna
//
//  Created by Claude Fable 5 (Anthropic) on 2026-09-08.
//

import SwiftUI
import SFSafeSymbols

/// A floating panel of sliders for every simulation constant. Changing any value wakes the simulation immediately so the layout responds while the slider moves; changing the connection threshold also rebuilds the edges.
/// - Authored by: Claude Fable 5 (Anthropic)
struct SimulationControlsView: View {
    @Bindable var parameters: SimulationParameters
    var model: NoteGraphModel

    init(model: NoteGraphModel) {
        self.model = model
        self.parameters = model.parameters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Simulation")
                    .font(.headline)
                Spacer()
                if model.simulation.isSettled {
                    Label("Settled", systemSymbol: .moonZzz)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                }
                Button("Reset") {
                    parameters.reset()
                    model.rebuildEdges()
                }
                .controlSize(.small)
            }

            parameterSlider("Connection threshold", value: $parameters.connectionThreshold, in: 0...1.5, format: "%.2f") {
                model.rebuildEdges()
            }
            parameterSlider("Spring stiffness", value: $parameters.springStiffness, in: 0...20, format: "%.1f")
            parameterSlider("Spring rest gap", value: $parameters.springRestGap, in: 0...300, format: "%.0f")
            parameterSlider("Repulsion", value: $parameters.repulsionStrength, in: 0...2_000_000, format: "%.0f")
            parameterSlider("Repulsion radius", value: $parameters.repulsionRadius, in: 50...3_000, format: "%.0f")
            parameterSlider("Center gravity", value: $parameters.centerStrength, in: 0...5, format: "%.2f")
            parameterSlider("Mass influence", value: $parameters.massInfluence, in: 0...2, format: "%.2f")
            parameterSlider("Damping", value: $parameters.damping, in: 0.5...15, format: "%.1f")
            parameterSlider("Max speed", value: $parameters.maxSpeed, in: 50...4_000, format: "%.0f")
            parameterSlider("Sleep speed", value: $parameters.sleepSpeed, in: 0.5...50, format: "%.1f")

            Toggle("Resolve collisions", isOn: $parameters.collisionsEnabled)
                .onChange(of: parameters.collisionsEnabled) { model.simulation.wake() }
            Toggle("Show connections", isOn: $parameters.showsConnections)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(12)
        .frame(width: 280)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }

    /// A labeled slider showing its current value that wakes the simulation on every change.
    /// - Authored by: Claude Fable 5 (Anthropic)
    private func parameterSlider(_ label: String, value: Binding<Double>, in range: ClosedRange<Double>, format: String, onChange: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            Slider(value: value, in: range)
                .onChange(of: value.wrappedValue) {
                    onChange?()
                    model.simulation.wake()
                }
        }
    }
}
