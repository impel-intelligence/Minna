//
//  CanvasView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/27/26.
//  Adapted from: https://github.com/benjaminRoberts01375/SwiftUI-Infinite-Grid/tree/main
//

import SwiftUI
import CoreGraphics
import InfiniteGrid

extension CGPoint {
    func translate(by translation: CGSize) -> CGPoint {
        return CGPoint(x: x + translation.width, y: y + translation.height)
    }
    
    static func / (lhs: Self, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    static func * (lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension CGSize {
    static func + (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func - (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    static func * (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    static func / (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }

    func inverted() -> CGSize {
        CGSize(width: -width, height: -height)
    }
}

extension CGSize {
    static func += (lhs: inout Self, rhs: Self) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }
}

struct NoteView: View {
    @State var position: CGPoint = .zero
    @Binding var scale: CGFloat
    
    @State var previousFrameTranslation: CGSize = .zero

    var body: some View {
        Text("Hello World")
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(.background)
                    .shadow(radius: 3)
            }
            .scaleEffect(CGSize(width: scale, height: scale))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        let delta = value.translation - previousFrameTranslation
                        position = position.translate(by: delta / scale)
                        previousFrameTranslation = value.translation
                    }
                    .onEnded { _ in
                        previousFrameTranslation = .zero
                    }
            )
            .position(position * scale)
    }
}

struct CanvasView: View {
    let gridShading: GraphicsContext.Shading = GraphicsContext.Shading.color(.primary.opacity(0.5))

    @State var translation: CGPoint = .zero
    @State var scale: CGFloat = 1
    @State var interactionPoint: CGPoint = .zero

    var body: some View {
        InfiniteGrid(gridShading: gridShading, lineThickness: 1, translation: $translation, scale: $scale, interactionPoint: $interactionPoint) {
            NoteView(scale: $scale)
        }
    }
}

#Preview {
    CanvasView()
        .frame(width: 300, height: 300)
}
