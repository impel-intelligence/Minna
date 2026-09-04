//
//  CanvasView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/27/26.
//

import SwiftUI
import CoreGraphics
import InfiniteGrid

struct CanvasView<Content: View>: View {
    let gridShading: GraphicsContext.Shading = GraphicsContext.Shading.color(.primary.opacity(0.5))

    @Binding var scale: CGFloat
    @Binding var translation: CGPoint
    @State var interactionPoint: CGPoint = .zero
    
    let content: Content

    init(translation: Binding<CGPoint>, scale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._scale = scale
        self._translation = translation

        self.content = content()
    }

    var body: some View {
        InfiniteGrid(gridShading: gridShading, lineThickness: 1, translation: $translation, scale: $scale, interactionPoint: $interactionPoint) {
            content
        }
    }
}

#Preview {
    CanvasView(translation: .constant(.zero), scale: .constant(1)) {
        Text("Hello")
    }
    .frame(width: 300, height: 300)
}
