//
//  FrameReader.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func frameReader(in coordinateSpace: CoordinateSpace = .global, callback: @escaping (CGRect) -> Void) -> some View {
        self.background {
            GeometryReader { geometry in
                let frame = geometry.frame(in: coordinateSpace)
                
                Color.clear
                    .onChange(of: frame, { _, _ in
                        callback(frame)
                    })
                    .onAppear {
                        callback(frame)
                    }
            }
            .hidden()
        }
    }
}
