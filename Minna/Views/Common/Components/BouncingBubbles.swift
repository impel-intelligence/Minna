//
//  BouncingBubbles.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

import SwiftUI
import Combine

struct BouncingBubbles: View {
    static let colorOpacity: Double = 0.7

    @State private var currentIndex: Int = -1

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let text: String

    @State private var animate = false
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
            .overlay {
                GeometryReader { geometry in
                    // Double the colors and lay them out across twice the width, then slide by exactly one width.
                    LinearGradient(
                        colors: colors + colors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: animate ? 0 : -geometry.size.width)
                }
            }
            .mask {
                content
            }
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
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
    BouncingBubbles(text: "Calculating")
}
