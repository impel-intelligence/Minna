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
import SFSafeSymbols
import IrisSearch
import IrisCommon
import Logging

struct CitationColumnView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    @Environment(\.router) private var router
    @Environment(\.openWindow) private var openWindow
    
    @Binding var citations: OrderedSet<Citation>
    @State var files: [File] = []
    @State var citationLocations: [UUID: [Int: EmbeddableContent]] = [:]

    var body: some View {
        List {
            Section("References") {
                ForEach(files.enumerated(), id: \.offset) { (offset, file) in
                    VStack {
                        HStack(spacing: 0) {
                            Text("\(offset + 1)")
                                .font(.headline)
                                .fontWeight(.medium)
                                .padding(5)
                                .background {
                                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 8, bottomLeading: 8))
                                        .foregroundStyle(Color.accentColor.opacity(0.2))
                                }
                            OpaqueFileCard(file: file, enableEditing: false, isEditingText: .constant(false), viewMode: .constant(.list), selectedFiles: .constant([]))
                        }
                        if let citation = citations.first(where: {$0.id == file.uuid}), !citation.pieces.isEmpty {
                            referenceSnippet(for: citation, offset: offset)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.sidebar)
        .onChange(of: citations, initial: true) {  _, newValue in
#if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                return
            }
#endif
            
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
            
            Task(priority: .high) {
                var localCitationLocations: [UUID: [Int: EmbeddableContent]] = [:]

                for citation in citations {
                    for piece in citation.pieces {
                        if let dbPiece = try? await irisContext.database.readPiece(uuid: citation.id, pieceSequence: piece) {
                            localCitationLocations[citation.id, default: [:]][piece] = dbPiece.content
                        }
                    }
                }
                
                citationLocations = localCitationLocations
            }
        }
    }
    
    @ViewBuilder
    func referenceSnippet(for citation: Citation, offset: Int) -> some View {
        if citationLocations[citation.id] != nil {
            HStack {
                // Provide the same spacing that the HStack above has by just copying the citation text and hiding it
                Text("\(offset + 1)")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding(5)
                    .opacity(0)
                VStack {
                    ForEach(citation.pieces.enumerated(), id: \.offset) { (offset, piece) in
                        if let embeddable = citationLocations[citation.id]?[piece] {
                            Button {
                                guard let url = citation.urlComponents(pieces: [piece]).url else { return }
                                do {
                                    try URLHandler.handle(url, context: modelContext, router: router, openWindow: openWindow)
                                } catch {
                                    Log.logger.error("Failed to open citation", error: error, metadata: ["url": "\(url)"])
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    Text("s\(offset + 1)")
                                    if let text = embeddable.textContent {
                                        Text(": \(text)")
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemSymbol: .arrowUpRight)
                                        .accessibilityLabel("Open Location")
                                }
                                .padding(5)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundStyle(Color.accentColor.opacity(0.2))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    @Previewable @State var citations: OrderedSet<Citation> = [
        Citation(id: UUID(), title: "The first cited document", pieces: []),
        Citation(id: UUID(), title: "The second cited document", pieces: [1]),
        Citation(id: UUID(), title: "The third cited document", pieces: [1, 10]),
        Citation(id: UUID(), title: "The fourth cited document", pieces: [4, 2, 30])
    ]
    
    CitationColumnView(citations: $citations, files: citations.map { citation in
        return File(uuid: citation.id, createdAt: .now, folder: Folder(name: "t", icon: FolderIcon(symbol: .emoji("3"), color: .azure)), title: citation.title, shortDescription: "sad", color: .random, type: ContentType.pdf, url: URL(string: "https://google.com")!, bookmark: nil, source: "Hello")
    }, citationLocations: citations.reduce(into: [UUID: [Int: EmbeddableContent]]()) { partialResult, citation in
        for piece in citation.pieces {
            let content = "Hello World this is a long string of text that is the content of the citation."
            partialResult[citation.id, default: [:]][piece] = .text(content: content, location: DocumentLocation(sequenceIndex: 0, documentLength: 10000, anchor: .pdf(page: 1, characterRange: 0..<content.count)))
        }
    })
    .modelContext(SampleDatabase.shared.context)
    .irisContext(IrisContext(modelContainer: SampleDatabase.shared.modelContainer))
}
