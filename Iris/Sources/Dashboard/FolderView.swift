//
//  FolderView.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

struct FolderView: View, Navigable {
    static let label: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> = Label {
        Text("Recents")
    } icon: {
        Image(.clock)
            .accessibilityLabel("clock")
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    FolderView()
}
