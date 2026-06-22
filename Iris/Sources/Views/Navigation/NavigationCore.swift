//
//  NavigationCore.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftData
import SwiftUI
import SFSafeSymbols

public struct NavigationCore: View {
    @Environment(\.undoManager) private var undoManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    
    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \.order) private var folders: [Folder]

    @AppStorage("knowledgeExpanded") var knowledgeExpanded: Bool = true
    @AppStorage("connectionsExpanded") var connectionsExpanded: Bool = true

    @State var addFolderRequest: AddFolderRequest? = nil
    
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
                    KnowledgeBaseContent(folders: folders, addFolder: addFolder(in:))
                }

                Section("Connections", isExpanded: $connectionsExpanded) {}
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button {
                        addFolder(in: nil)
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    .accessibilityIdentifier("navigation.addItem")
                }
            }
        } detail: {
            Text("Select an item")
        }
        .onAppear {
            modelContext.undoManager = undoManager
        }
        .sheet(item: $addFolderRequest) { request in
            AddFolderForm(parentFolder: request.parent)
        }
    }

    func addFolder(in folder: Folder?) {
        print("Adding folder with parent \(folder?.name ?? "No parent")")
        addFolderRequest = AddFolderRequest(parent: folder)
    }
}




#Preview {
    NavigationCore()
        .modelContainer(SampleDatabase.shared.modelContainer)
}
