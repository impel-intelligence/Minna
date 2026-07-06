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
    var placeHolder: String
    @Binding var searchQuery: String
    let theme: ThemeColor
    let submit: () -> Void

    var body: some View {
        HStack {
            Image(systemSymbol: .magnifyingglass)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(placeHolder, text: $searchQuery)
                .textFieldStyle(.plain)
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
        .glassEffect(.regular, in: .rect(cornerRadius: 100))
        .shadow(color: theme.background.opacity(0.18), radius: 18, x: 0, y: 8)

        .onSubmit {
            submit()
        }
    }
}

#Preview {
    @Previewable @State var searchQuery: String = "Hello"
    SearchBar(placeHolder: "Hello World", searchQuery: $searchQuery, theme: .random) {
        print("Hello")
    }
}
