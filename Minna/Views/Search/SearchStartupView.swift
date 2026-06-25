
//
//  SearchStartupView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSafeSymbols
import SwiftData
import SentrySwift
import OrderedCollections

struct SearchStartupView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext

    @State private var orderedSearch: [File] = []

    @State var searchQuery: String = ""
    @State var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(spacing: 5) {
                Image("impel_logo")
                    .resizable()
                    .frame(width: 45, height: 45)
                    .accessibilityHidden(true)
                Text("Hey \(NSUserFirstName())!")
                    .font(.system(size: 36, design: .serif))
            }
            
            VStack(spacing: 0) {
                SearchBar(placeHolder: "Search or Ask across your Knowledge", searchQuery: $searchQuery)
                
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

            ScrollView(.horizontal) {
                HStack {
                    ForEach(orderedSearch) { file in
                        OpaqueFileCard(file: file, isEditingText: .constant(false), viewMode: .constant(.grid), selectedFiles: .constant([]))
                    }
                }
            }
            Spacer()
        }
        .navigationTitle("Ask Minna", image: Image(systemSymbol: .sparkles2).accessibilityHidden(true))
        .onChange(of: searchQuery) { _, newValue in
            searchIrisIndex(query: newValue)
        }
    }
    
    func searchIrisIndex(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            orderedSearch = []
            return
        }

        searchTask = Task {
            // Debounce: wait 20ms before searching
            try? await Task.sleep(for: Duration.milliseconds(20))

            // Check if cancelled during wait
            guard !Task.isCancelled else { return }

//            isLoading = true
            do {
                let searchedUUIDs = try await irisContext.search(query: query)
                orderedSearch = fetchOrderedFiles(for: searchedUUIDs)
            } catch is CancellationError {
                return
            } catch {
                SentrySDK.capture(error: error)
                print("Failed to search \(error)")
            }
//            isLoading = false
        }

    }

    /// Fetch the files matching the search result UUIDs and order them by their rank in the results.
    private func fetchOrderedFiles(for searchedUUIDs: [UUID]) -> [File] {
        guard !searchedUUIDs.isEmpty else { return [] }

        let descriptor = FetchDescriptor<File>(predicate: #Predicate<File> { file in
            searchedUUIDs.contains(file.uuid)
        })

        guard let files = try? modelContext.fetch(descriptor) else { return [] }

        // Pre-size an array for ordered results and place docs directly by rank
        var orderedByRank = [File?](repeating: nil, count: searchedUUIDs.count)

        // O(n) loop over the retrieved documents, placing each document into the array at its rank position.
        for file in files {
            guard let index = searchedUUIDs.firstIndex(of: file.uuid) else { continue }
            orderedByRank[index] = file
        }

        // Compact the rank order list, to remove any documents that were not found.
        return orderedByRank.compactMap { $0 }
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
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(placeHolder, text: $searchQuery)
                .textFieldStyle(.plain)
        }
        .font(.body)
        .fontWeight(.medium)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: 500)
        .glassEffect(.regular, in: .rect(cornerRadius: 100))
    }
}

#Preview {
    SearchStartupView()
        .navigationTitle("Ask Minna")
        .irisContext(IrisDBController(modelContainer: SampleDatabase.shared.modelContainer).mainContext)
}
