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

    @State var translation: CGPoint = .zero
    @State var scale: CGFloat = 1
    @State var interactionPoint: CGPoint = .zero
    
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        InfiniteGrid(gridShading: gridShading, lineThickness: 1, translation: $translation, scale: $scale, interactionPoint: $interactionPoint) {
            content
        }
    }
}

#Preview {
    CanvasView {
        Text("Hello")
    }
    .frame(width: 300, height: 300)
}
