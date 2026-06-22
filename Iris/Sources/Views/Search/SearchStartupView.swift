//
//  SearchStartupView.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSafeSymbols

struct SearchStartupView: View, Navigable {
    static var label: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> {
        Label {
            Text("Search")
        } icon: {
            Image(systemSymbol: .magnifyingglass)
                .accessibilityHidden(true)
        }
    }
    
    var body: some View {
        Text("Search!")
    }
}

#Preview {
    SearchStartupView()
}
