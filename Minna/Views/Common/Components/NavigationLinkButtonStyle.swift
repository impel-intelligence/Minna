//
//  NavigationLinkButtonStyle.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import SFSafeSymbols

struct NavigationLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LabeledContent {
            Image(systemSymbol: .chevronRight)
                .imageScale(.small)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        } label: {
            configuration.label
        }
    }
}
