//
//  NavigationCore.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftData
import SwiftUI

public struct NavigationCore: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \.order) private var folders: [Folder]

    @AppStorage("knowledgeExpanded") var knowledgeExpanded: Bool = true
    @AppStorage("connectionsExpanded") var connectionsExpanded: Bool = true

    public var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    SearchStartupView()
                } label: {
                    SearchStartupView.label
                }
                NavigationLink {
                    RecentsView()
                } label: {
                    RecentsView.label
                }

                Section("Knowledge Base", isExpanded: $knowledgeExpanded) {
                    KnowledgeBaseContent(folders: folders)
                }

                Section("Connections", isExpanded: $connectionsExpanded) {}
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityIdentifier("navigation.addItem")
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newFolder = Folder(name: "Test Folder", icon: FolderIcon(symbol: .symbol("star.hexagon.fill")), order: folders.count)
            modelContext.insert(newFolder)
        }
    }
}

struct KnowledgeBaseContent: View {
    @Environment(\.modelContext) private var modelContext
    var folders: [Folder]

    var body: some View {
        ForEach(folders) { folder in
            FolderRow(folder: folder)
        }
        .onMove { source, destination in
            FolderRow.reorder(folders, from: source, to: destination)
        }
    }
}

struct FolderRow: View {
    @Environment(\.modelContext) private var modelContext
    let folder: Folder

    var body: some View {
        if let children = folder.displayChildren {
            DisclosureGroup {
                ForEach(children) { child in
                    FolderRow(folder: child)
                }
                .onMove { source, destination in
                    if let displayChildren = folder.displayChildren {
                        FolderRow.reorder(displayChildren, from: source, to: destination)
                    }
                }
            } label: {
                sidebarFolderItem(folder: folder)
            }
        } else {
            sidebarFolderItem(folder: folder)
        }
    }

    private func sidebarFolderItem(folder: Folder) -> some View {
        NavigationLink {
            FolderView(folder: folder)
        } label: {
            folder.label()
                .contextMenu {
                    if !folder.protected {
                        Button("Add Child") {
                            withAnimation {
                                let newFolder = Folder(name: "Subfolder \(folder.children.count)", icon: FolderIcon(symbol: .symbol("star")))

                                folder.children.append(newFolder)
                                newFolder.parent = folder

                                modelContext.insert(newFolder)
                            }
                        }
                        Button("Delete") {
                            withAnimation {
                                if !folder.children.isEmpty, let parent = folder.parent {
                                    for child in folder.children {
                                        child.parent = parent
                                    }
                                }

                                modelContext.delete(folder)
                            }
                        }
                    }
                }
        }
    }

    static func reorder(_ items: [Folder], from source: IndexSet, to destination: Int) {
        withAnimation {
            var mutableItems = items
            mutableItems.move(fromOffsets: source, toOffset: destination)

            for (index, item) in mutableItems.enumerated() {
                item.order = index
            }
        }
    }
}

#Preview {
    NavigationCore()
        .modelContainer(SampleDatabase.shared.modelContainer)
}
