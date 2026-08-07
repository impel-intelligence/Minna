//
//  SearchBar.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

import SwiftUI
import SFSafeSymbols
import DatabaseSchema

struct SearchBar: View {
    @Environment(\.theme) var theme
    
    var placeHolder: String
    @Binding var searchQuery: String
    let submit: () -> Void

    var body: some View {
        HStack {
            Image(systemSymbol: .magnifyingglass)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(placeHolder, text: $searchQuery, axis: .vertical)
                .textFieldStyle(.plain)
                .onSubmit {
                    submit()
                }
            if !searchQuery.isEmpty {
                Button {
                    submit()
                } label: {
                    Image(systemSymbol: .return)
                        .accessibilityLabel("Submit entered text.")
                }
                .buttonStyle(.plain)
            }
        }
        .font(.body)
        .fontWeight(.medium)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: 500)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .shadow(color: theme.background.opacity(0.18), radius: 18, x: 0, y: 8)
    }
}

#Preview {
    @Previewable @State var searchQuery: String = "Hello"
    @FocusState var hello: Bool

    SearchBar(placeHolder: "Hello World", searchQuery: $searchQuery) {
        print("Hello")
    }
    .theme(.random)
    .frame(width: 500, height: 500)
}
