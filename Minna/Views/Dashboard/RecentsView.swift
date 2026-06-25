//
//  RecentsView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSafeSymbols

struct RecentsView: View, Navigable {
    static let label: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> = Label {
        Text("Recents")
    } icon: {
        Image(systemSymbol: .clock)
            .accessibilityHidden(true)
    }
    
    var body: some View {
        Text("Recents")
    }
}

#Preview {
    RecentsView()
}
