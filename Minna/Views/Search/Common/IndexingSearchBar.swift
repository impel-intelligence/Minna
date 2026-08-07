//
//  IndexingSearchBar.swift
//  Minna
//
//  Created by Taylor Lineman on 7/8/26.
//

import SwiftUI
import ModelCDN
import DatabaseSchema

struct IndexingSearchBar: View {
    @Environment(\.theme) var theme
    @Environment(\.irisContext) var irisContext
    @Environment(ModelManager.self) var manager
    
    var placeHolder: String
    @Binding var searchQuery: String
    @Binding var isGenerating: Bool
    let submit: () -> Void
    let cancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(placeHolder: placeHolder, searchQuery: $searchQuery, submit: submit)

            if !manager.inFlightDownloads.isEmpty {
                ForEach(manager.inFlightDownloads) { download in
                    progressView(for: download.progress, title: download.file.name)
                }
            }
            
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
    
    @ViewBuilder
    func progressView(for progress: Progress, title: String) -> some View {
        HStack {
            Text(title)
            ProgressView(value: progress.fractionCompleted)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: 450)
    }
}

#Preview {
    @Previewable @State var searchQuery = ""
    @Previewable @State var isGenerating = false
    @Previewable@State var modelManager: ModelManager = ModelManager()

    IndexingSearchBar(placeHolder: "Hello World", searchQuery: $searchQuery, isGenerating: $isGenerating, submit: {
        
    }, cancel: {
        
    })
    .environment(modelManager)
    .irisContext(.notConnected)
    .database(SampleDatabase.shared)
    .theme(.champagne)
}
