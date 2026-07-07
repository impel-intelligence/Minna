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
    @State var files: [File] = []

    var body: some View {
        List {
            Section("References") {
                ForEach(files.enumerated(), id: \.offset) { (offset, file) in
                    HStack(spacing: 0) {
                        Text("\(offset)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .padding(5)
                            .background {
                                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 8, bottomLeading: 8))
                                    .foregroundStyle(Color.accentColor.opacity(0.2))
                            }
                        ListFileCard(file: file, editingTitle: .constant(false), editingDescription: .constant(false))
                    }
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
    @Previewable @State var files: [File] = [
        File(createdAt: .now, folder: Folder(name: "t", icon: FolderIcon(symbol: .emoji("3"), color: .azure)), title: "Hell", shortDescription: "sad", color: .random, type: ContentType.pdf, url: URL(string: "https://google.com")!, bookmark: nil, source: "Hello")
    ]
    
    
    CitationColumnView(citations: $citations, files: files)
}
