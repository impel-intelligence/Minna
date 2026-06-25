//
//  FolderRow.swift
//  Minna
//
//  Created by Taylor Lineman on 6/22/26.
//

import SwiftUI
import SFSafeSymbols
import SwiftData

struct FolderRow: View {
    @Environment(\.modelContext) private var modelContext

    @State var folder: Folder

    let addFolder: (Folder?) -> Void
    
    @FocusState var focusState: Bool

    var body: some View {
        if let children = folder.displayChildren {
            DisclosureGroup {
                ForEach(children) { child in
                    FolderRow(folder: child, addFolder: addFolder)
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
        Label {
            HStack {
                if folder.protected {
                    Text(folder.name)
                } else {
                    TextField("Name", text: $folder.name)
                        .focused($focusState, equals: true)
                }
                Spacer()
                if !folder.files.isEmpty {
                    Text(folder.files.count.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            folder.icon.image()
        }
        .tag(NavigationDestination.folder(folder))
        .contextMenu {
            if !folder.protected {
                Button {
                    print("Add folder \(folder.name)")
                    addFolder(folder)
                } label: {
                    Label("Create Subfolder", systemSymbol: .plus)
                }
                Button {
                    focusState = true
                } label: {
                    Label("Rename", systemSymbol: .pencilLine)
                }

                Button(role: .destructive) {
                    withAnimation {
                        if !folder.children.isEmpty, let parent = folder.parent {
                            for child in folder.children {
                                child.parent = parent
                            }
                        }
                        
                        modelContext.delete(folder)
                    }
                } label: {
                    Label("Delete", systemSymbol: .trash)
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
