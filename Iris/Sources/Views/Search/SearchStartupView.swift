//
//  SearchStartupView.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSymbols

struct SearchStartupView: View, Navigable {
    static var label: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> {
        Label {
            Text("Search")
        } icon: {
            Image(.magnifyingglass)
                .accessibilityLabel(SFSymbol.magnifyingglass.name)
        }
    }
    
    var body: some View {
        Text("Search!")
    }
}

#Preview {
    SearchStartupView()
}
