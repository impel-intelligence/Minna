//
//  MinnaCodeBlockStyle.swift
//  Minna
//
//  Created by Taylor Lineman on 6/30/26.
//

import DatabaseSchema
import Textual
import SwiftUI
import SFSafeSymbols

struct MinnaCodeBlockStyle: StructuredText.CodeBlockStyle {
    let theme: ThemeColor
    
    func makeBody(configuration: Configuration) -> some View {
        Overflow {
            configuration.label
                .textual.lineSpacing(.fontScaled(0.225))
                .textual.fontScale(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .monospaced()
                .padding(5)
        }
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .textual.blockSpacing(.init(top: 5, bottom: 5))
        .overlay(alignment: .topTrailing) {
            Button {
                configuration.codeBlock.copyToPasteboard()
            } label: {
                Image(systemSymbol: .documentOnDocument)
                    .accessibilityLabel("Copy Code")
            }
            .buttonStyle(MinnaCopyCodeBlockButtonStyle())
            .padding([.top, .trailing], 2)
        }
    }
}

struct MinnaCopyCodeBlockButtonStyle: ButtonStyle {
    @State var hovering: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .imageScale(.small)
            .frame(width: 20, height: 20)
            .background(.secondary.opacity(0.1))
            .clipShape(.rect(cornerRadius: 5))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            
    }
}
