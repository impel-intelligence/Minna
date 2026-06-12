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
    @Query(filter: #Predicate<Folder> { $0.parent == nil }) private var folders: [Folder]
    
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
                    OutlineGroup(folders, children: \.displayChildren) { folder in
                        sidebarFolderItem(folder: folder)
                    }
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
    
    @ViewBuilder
    private func sidebarFolderItem(folder: Folder) -> some View {
        NavigationLink {
            Text(folder.name)
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
                            let newFolder = Folder(name: "Subfolder", icon: FolderIcon(symbol: .symbol("star")))
                            
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
                            modelContext.delete(folder)
                        }
                    }
                }
            }
        }

    }

    private func addItem() {
        withAnimation {
            let newFolder = Folder(name: "Test Folder", icon: FolderIcon(symbol: .symbol("star.hexagon.fill")))
            modelContext.insert(newFolder)
        }
    }
}

#Preview {
    NavigationCore()
        .modelContainer(for: Folder.self, inMemory: true)
}
