//
//  IndexingSearchBar.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

import SwiftUI

struct IndexingSearchBar: View {
    @Environment(\.theme) var theme
    @Environment(\.irisContext) var irisContext
    
    var placeHolder: String
    @Binding var searchQuery: String
    let submit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(placeHolder: placeHolder, searchQuery: $searchQuery, submit: submit)
            
            if let progress = irisContext.indexingProgress, progress.isIndexing {
                HStack {
                    Text("Indexing...")
                    ProgressView(value: progress.fractionCompleted)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 450)
            }
        }
    }
}
