
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
import DatabaseSchema

struct SearchStartupView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.database) var database
    @Environment(NavigationRouter.self) private var navigationRouter

    @Namespace var chatTransitionNamespace

    @State private var orderedSearch: [File] = []

    @State var searchQuery: String = ""
    @State var searchTask: Task<Void, Never>?
    
    @State var theme: ThemeColor = .random

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(spacing: 5) {
                Image("impel_logo")
                    .resizable()
                    .frame(width: 45, height: 45)
                    .accessibilityLabel("Minna Logo")
                    .matchedTransitionSource(id: "logo", in: chatTransitionNamespace)
                Text("Hey \(NSUserFirstName())!")
                    .font(.system(size: 36, design: .serif))
            }
            
            IndexingSearchBar(placeHolder: "Search or Ask across your Knowledge", searchQuery: $searchQuery) {
                do {
                    let unfilledUUID = database.unfilledFolderUUID
                    var descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == unfilledUUID })
                    descriptor.fetchLimit = 1
                    let folders = try modelContext.fetch(descriptor)
                    guard let unfilledFolder = folders.first else { return }
                    
                    let newChat = Chat.create(in: unfilledFolder, context: modelContext)
                    navigationRouter.push(newChat)
                } catch {
                    print("Failed to create chat: \(error)")
                }
            }
            .theme(theme)
            .matchedTransitionSource(id: "searchBar", in: chatTransitionNamespace)

//            ScrollView(.horizontal) {
//                HStack {
//                    ForEach(orderedSearch) { file in
//                        OpaqueFileCard(file: file, isEditingText: .constant(false), viewMode: .constant(.grid), selectedFiles: .constant([]))
//                    }
//                }
//            }
            Spacer()
        }
        .navigationTitle("Ask Minna", image: Image(systemSymbol: .sparkles2).accessibilityHidden(true))
//        .onChange(of: searchQuery) { _, newValue in
//            searchIrisIndex(query: newValue)
//        }
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

#Preview {
    SearchStartupView()
        .navigationTitle("Ask Minna")
        .environment(NavigationRouter())
        .irisContext(IrisDBController(modelContainer: SampleDatabase.shared.modelContainer).mainContext)
}
