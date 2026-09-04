//
//  DraggableView.swift
//  Minna
//
//  Created by Taylor Lineman on 8/28/26.
//

import SwiftUI

struct DraggableView<Content: View>: View {
    @State var position: CGPoint = .zero
    @Binding var scale: CGFloat
    
    @State var previousFrameTranslation: CGSize = .zero

    @ViewBuilder var content: Content
    
    var body: some View {
        content
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
