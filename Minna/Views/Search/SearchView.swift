//
//  SearchView.swift
//  Minna
//
//  Created by Taylor Lineman on 7/22/26.
//

import SwiftUI
import SwiftData
import DatabaseSchema
import Logging

struct SearchView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    
    @State var searchRouter: RouterCore?

    @State var searchResults: [File] = []
    
    @State var searchQuery: String = ""
    
    @State var searchTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(searchResults) { file in
                    ListFileCard(file: file, editingTitle: .constant(false), editingDescription: .constant(false))
                        .id(file)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .scrollTargetLayout()
        }
        .safeAreaInset(edge: .bottom) {
            IndexingSearchBar(placeHolder: "Search or Ask across your knowledge", searchQuery: $searchQuery) {
                Task {
                    let tmpQuery = searchQuery
                    searchQuery = ""
                    do {
                        try await submitSearchResult(query: tmpQuery)
                    } catch {
                        searchQuery = tmpQuery
                        print("Failed to submit search results \(error)")
                    }
                }
            }
            .padding(.bottom)
        }
        .onAppear {
            do {
                searchRouter = try RouterCore()
            } catch {
                Log.logger.error("Failed to create search router", error: error)
            }
        }
        .onChange(of: searchQuery) { _, newValue in
            searchTask?.cancel()

            searchTask = Task {
                // Debounce: wait 20ms before searching
                try? await Task.sleep(for: Duration.milliseconds(50))
                
                // Check if cancelled during wait
                guard !Task.isCancelled else { return }
                
                do {
                    try await searchIris(query: newValue)
                } catch is CancellationError {
                    
                } catch {
                    print("Failed to search iris \(newValue) \(error)")
                }
            }
        }
    }
    
    func submitSearchResult(query: String) async throws {
        guard let searchRouter else {
            print("No Search Router Available")
            return
        }
        
        let destination = try searchRouter.predict(query)
//        switch destination {
//        case .search:

        //        case .aiAssistant, nil:
//            // Send to AI to handle
//            break
//        }
    }
    
    func searchIris(query: String) async throws {
        let fileUUIDs = try await irisContext.search(query: query)
        
        let descriptor = FetchDescriptor<File>(predicate: #Predicate { fileUUIDs.contains($0.uuid) })
        let unsorted = try modelContext.fetch(descriptor)
        
        let searchRanking = fileUUIDs.enumerated().reduce(into: [:]) { partialResult, element in
            partialResult[element.element] = element.offset
        }
        var orderedByRank = [File?](repeating: nil, count: fileUUIDs.count)
        
        // O(n) loop over the retrieved documents, placing each document into the array at its rank position.
        for file in unsorted {
            if let rank = searchRanking[file.uuid] {
                orderedByRank[rank] = file
            }
        }
        
        searchResults = orderedByRank.compactMap { $0 }
    }
}

#Preview {
    SearchView()
}
