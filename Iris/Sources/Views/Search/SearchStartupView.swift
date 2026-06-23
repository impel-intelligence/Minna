//
//  SearchStartupView.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSafeSymbols

struct SearchStartupView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    
    @State var searchQuery: String = ""
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(spacing: 5) {
                Image("impel_logo")
                    .resizable()
                    .frame(width: 45, height: 45)
                Text("Hey \(NSUserFirstName())!")
                    .font(.system(size: 36, design: .serif))
            }
            SearchBar(placeHolder: "Search or Ask across your Knowledge", searchQuery: $searchQuery)
            Spacer()
        }
        .navigationTitle("Ask Iris", image: Image(systemSymbol: .sparkles2))
    }
}

extension SearchStartupView: Navigable {
    static var label: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> {
        Label {
            Text("Search")
        } icon: {
            Image(systemSymbol: .magnifyingglass)
                .accessibilityHidden(true)
        }
    }
}

struct SearchBar: View {
    var placeHolder: String
    @Binding var searchQuery: String
    
    var body: some View {
        HStack {
            Image(systemSymbol: .magnifyingglass)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            TextField(placeHolder, text: $searchQuery)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: 500)
        .glassEffect(.regular, in: .rect(cornerRadius: 100))
    }
}

#Preview {
    SearchStartupView()
        .navigationTitle("Ask Iris")
}
