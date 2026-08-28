//
//  CanvasView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/27/26.
//  Adapted from: https://github.com/benjaminRoberts01375/SwiftUI-Infinite-Grid/tree/main
//

import SwiftUI
import CoreGraphics
import Textual

extension CGPoint {
    func translate(by translation: CGSize) -> CGPoint {
        return CGPoint(x: x + translation.width, y: y + translation.height)
    }
}

extension CGSize {
    static func + (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func - (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}

extension CGSize {
    static func += (lhs: inout Self, rhs: Self) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }
}

struct CanvasView: View {
    let lineSpacing: CGFloat = 20
    let gridShading: GraphicsContext.Shading = GraphicsContext.Shading.color(.primary.opacity(0.5))
    let gridStyle: StrokeStyle = StrokeStyle(lineWidth: 1)
    
    @State var gridScale: CGFloat = 1
    @State var previousGridScale: CGFloat = 1
    
    @State var gridTranslation: CGSize = .zero
    @State var previousFrameTranslation: CGSize = .zero
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                let delta = value.translation - previousFrameTranslation
                gridTranslation += delta
                previousFrameTranslation = value.translation
            }
            .onEnded { _ in
                previousFrameTranslation = .zero
            }
    }
    
    var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                print(value.magnification)
                let delta = value.magnification / previousGridScale
                gridScale *= delta
                previousGridScale = value.magnification
                
                // Need to update the frame translation so the scaling is still centered on the current position
                // Need to limit scale so the grids do not get too small
            }
            .onEnded { _ in
                previousGridScale = 1
            }
    }
    
    var body: some View {
        ZStack {
            Canvas(opaque: false, colorMode: .extendedLinear) { context, size in
                let grid = CanvasView.grid(for: size, translation: gridTranslation, scale: gridScale, lineSpacing: lineSpacing)
                context.stroke(grid, with: gridShading, style: gridStyle)
            }
        }
        .gesture(dragGesture)
        .gesture(scaleGesture)
//        .simultaneousGesture(scaleGesture)
        
    }
    
    static func grid(for size: CGSize, translation: CGSize, scale: CGFloat, lineSpacing: CGFloat) -> Path {
        var path = Path()

        let lineSpacing = lineSpacing * scale
        
        // Figure out how far into a spacing the translation will put us. This creates the illusion that the grid is moving as we pan
        let xOffset = translation.width.truncatingRemainder(dividingBy: lineSpacing)
        let yOffset = translation.height.truncatingRemainder(dividingBy: lineSpacing)

        // Vertical Lines, using through adds a line at the edge.
        for offset in stride(from: xOffset, through: size.width + lineSpacing, by: lineSpacing) {
            let start = CGPoint(x: offset, y: 0)
            let end = CGPoint(x: offset, y: size.height)
            path.move(to: start)
            path.addLine(to: end)
        }
        
        // Horizontal Lines, using through adds a line at the edge.
        for offset in stride(from: yOffset, through: size.height + lineSpacing, by: lineSpacing) {
            let start = CGPoint(x: 0, y: offset)
            let end = CGPoint(x: size.width, y: offset)
            path.move(to: start)
            path.addLine(to: end)
        }
        
        return path
    }

}

#Preview {
    CanvasView()
        .frame(width: 300, height: 300)
}
