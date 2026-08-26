//
//  NavigationTitle.swift
//  Minna
//
//  Created by Taylor Lineman on 6/23/26.
//


import SwiftUI

extension View {
    @ViewBuilder
    func navigationTitle<Content>(_ title: LocalizedStringKey, image: Content, color: Color = .primary) -> some View where Content: View  {
        self
            .toolbar(removing: .title)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 3) {
                        image
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                        Text(title)
                    }
                    .font(.title3)
                    .bold()
                    .padding(.leading, 10)
                    .foregroundStyle(color)
//                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarSpacer(.flexible, placement: .navigation)
            }
    }
    
    @ViewBuilder
    func navigationTitle<Content>(_ title: String, image: Content, color: Color = .primary) -> some View where Content: View {
        self
            .navigationTitle(LocalizedStringKey(title), image: image, color: color)
    }

}
