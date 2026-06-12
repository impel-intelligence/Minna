//
//  NavigationCore.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftUI
import SwiftData

public struct NavigationCore: View {
    @Environment(\.modelContext) private var modelContext
    
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
                    KnowledgeBaseContent()
                }
                
                Section("Connections", isExpanded: $connectionsExpanded) {
                    
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func addItem() {
        withAnimation {
            let newFolder = Folder(name: "Test Folder", icon: FolderIcon(symbol: .symbol("star.hexagon.fill")))
            modelContext.insert(newFolder)
        }
    }
}

//struct ReOrderAbleDisclosureGroup<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
//    var data: Data
//    @ViewBuilder var content: (Data.Element) -> Content
//
//    var body: some View {
//        ForEach(data) { folder in
//            content(folder)
//        }
//    }
//}

struct KnowledgeBaseContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \.order) private var folders: [Folder]

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
    
    @ViewBuilder
    private func sidebarFolderItem(folder: Folder) -> some View {
        NavigationLink {
            FolderView()
        } label: {
            Label {
                Text(folder.name)
            } icon: {
                switch folder.icon.symbol {
                case .emoji(let emoji):
                    Text(emoji)
                case .symbol(let symbol):
                    Image(systemName: symbol)
                        .accessibilityLabel(symbol)
                }
            }
            .contextMenu {
                if !folder.protected {
                    Button("Add Child") {
                        withAnimation {
                            let newFolder = Folder(name: "Subfolder \(folder.children?.count ?? 0)", icon: FolderIcon(symbol: .symbol("star")))
                            
                            if folder.children == nil {
                                folder.children = []
                            }
                            
                            folder.children?.append(newFolder)
                            newFolder.parent = folder
                            
                            modelContext.insert(newFolder)
                        }
                    }
                    Button("Delete") {
                        withAnimation {
                            if let children = folder.children, let parent = folder.parent {
                                for child in children {
                                    child.parent = parent
                                    parent.children?.append(folder)
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
        .modelContainer(for: Folder.self, inMemory: true)
}
