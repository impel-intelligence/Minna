//
//  NavigationCore.swift
//  iris
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftData
import SwiftUI
import SFSafeSymbols
import SentrySwift

enum NavigationDestination: Hashable {
    case search
    case recents
    case folder(Folder)
}

public struct NavigationCore: View {
    @Environment(\.undoManager) private var undoManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    
    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \.order) private var folders: [Folder]

    @AppStorage("knowledgeExpanded") var knowledgeExpanded: Bool = true
    @AppStorage("connectionsExpanded") var connectionsExpanded: Bool = true

    @State var selectedDestination: NavigationDestination? = .search
    
    @State var addFolderRequest: AddFolderRequest?
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedDestination) {                
                SearchStartupView.label
                    .tag(NavigationDestination.search)

                RecentsView.label
                    .tag(NavigationDestination.recents)

                Section("Knowledge Base", isExpanded: $knowledgeExpanded) {
                    ForEach(folders) { folder in
                        FolderRow(folder: folder, addFolder: addFolder)
                    }
                    .onMove { source, destination in
                        FolderRow.reorder(folders, from: source, to: destination)
                    }
                }

                Section("Connections", isExpanded: $connectionsExpanded) {}
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button {
                        addFolder(in: nil)
                    } label: {
                        Label("Add Item", systemSymbol: .plus)
                    }
                    .accessibilityIdentifier("navigation.addItem")
                }
            }
        } detail: {
            switch selectedDestination {
            case .search, nil:
                SearchStartupView()
            case .recents:
                RecentsView()
            case .folder(let folder):
                FolderView(folder: folder)
                    .id(folder.uuid)
            }
        }
        .onAppear {
            modelContext.undoManager = undoManager
        }
        .sheet(item: $addFolderRequest) { request in
            AddFolderForm(parentFolder: request.parent)
        }
        .task {
            // Start indexing all files that did not complete indexing.
            let descriptor = FetchDescriptor<File>(predicate: #Predicate<File> { file in
                !file.backgroundTasks.searchIndexed
            })
            
            guard let files = try? modelContext.fetch(descriptor) else { return }
            for file in files {
                do {
                    try irisContext.reIndex(file)
                } catch {
                    SentrySDK.capture(error: error)
                    print("Failed to re-index file \(file)")
                }
            }
        }
        .task {
            // Generate descriptions for files without descriptions.
            let descriptor = FetchDescriptor<File>(predicate: #Predicate<File> { file in
                !file.backgroundTasks.descriptionGenerated
            })
            
            guard let files = try? modelContext.fetch(descriptor) else { return }
            for file in files {
                FrontendDatabase.shared.queueDescriptionUpdate(for: file)
            }
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
        .irisContext(IrisContext.notConnected)
}
