//
//  CitationColumnView.swift
//  Minna
//
//  Created by Taylor Lineman on 7/6/26.
//

import SwiftUI
import OrderedCollections
import DatabaseSchema
import SwiftData

struct CitationColumnView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var citations: OrderedSet<Citation>
    @State private var files: [File] = []

    var body: some View {
        List {
            Section("References") {
                ForEach(files.enumerated(), id: \.offset) { (offset, file) in
                    ListFileCard(file: file, editingTitle: .constant(false), editingDescription: .constant(false))
//                    HStack {
//                        Text("\(offset + 1)")
//                        Text(citation.title)
//                    }
                }
            }
        }
        .onChange(of: citations, initial: true) { _, newValue in
            let ids = newValue.map(\.id)
            let descriptor = FetchDescriptor<File>(predicate: #Predicate<File> { file in
                ids.contains(file.uuid)
            })
            
            let unsortedFiles = (try? modelContext.fetch(descriptor)) ?? []

            let orderDictionary = citations.enumerated().reduce(into: [:]) { dict, pair in
                dict[pair.element.id] = pair.offset
            }
            
            let sortedFiles = unsortedFiles.sorted {
                let index0 = orderDictionary[$0.uuid] ?? Int.max
                let index1 = orderDictionary[$1.uuid] ?? Int.max
                return index0 < index1
            }
            
            self.files = sortedFiles
        }
    }
}

#Preview {
    @Previewable @State var citations: OrderedSet<Citation> = [
        Citation(id: UUID(), title: "The first cited document"),
        Citation(id: UUID(), title: "The second cited document")
    ]
    
    CitationColumnView(citations: $citations)
}
