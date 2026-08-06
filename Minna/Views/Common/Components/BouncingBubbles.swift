//
//  BouncingBubbles.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-08-06

import SwiftUI
import Combine

struct BouncingBubbles: View {
    static let colorOpacity: Double = 0.7

    @State private var currentIndex: Int = -1

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let text: String

    @State private var colors: [Color] = [
        .red.opacity(colorOpacity),
        .orange.opacity(colorOpacity),
        .yellow.opacity(colorOpacity),
        .green.opacity(colorOpacity),
        .blue.opacity(colorOpacity),
        .indigo.opacity(colorOpacity),
        .purple.opacity(colorOpacity)
    ]

    var body: some View {
        content
            .id("bubble")
            .overlay {
                GeometryReader { geometry in
                    // Drive the gradient offset from wall-clock time so re-renders can never interrupt it.
                    TimelineView(.animation) { context in
                        let elapsed = context.date.timeIntervalSinceReferenceDate
                        let progress = elapsed.truncatingRemainder(dividingBy: 5.0) / 5.0
                        LinearGradient(
                            colors: colors + colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width * (1.0 - progress))
                    }
                }
            }
            .mask {
                content
            }
            .geometryGroup()
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex += 1
                if currentIndex >= 8 {
                    currentIndex = 0
                }
            }
        }
    }

    var content: some View {
        HStack(alignment: .bottom) {
            Text(text)
                .bold()
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 4, height: 4)
                        .phaseAnimator([false, true], trigger: index == currentIndex) { content, phase in
                            content.offset(y: phase ? -3 : 0)
                        } animation: { _ in
                            return .bouncy
                        }
                }
                .frame(height: 12)
            }
        }
    }
}

#Preview {
    BouncingBubbles(text: "Sifting through really long information")
}
