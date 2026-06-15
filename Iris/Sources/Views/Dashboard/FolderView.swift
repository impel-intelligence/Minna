//
//  FolderView.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SwiftData
import SFSymbols
import ViewStorage

enum FolderViewMode: Int, ViewStorable {
    case grid
    case list
}

struct FolderView: View {
    @Environment(\.modelContext) private var modelContext
    
    // WARN: Do not edit this query, its actual value is set in the initializer
    @Query private var files: [File]
    let folder: Folder
    
    @ViewStorage("viewMode", path: \Self.folder.uuid.uuidString) var viewMode: FolderViewMode = .grid
    
    init(folder: Folder) {
        self.folder = folder
        let id = folder.persistentModelID
                
        // This is funky! For some reason there is now way to filter a query when it enters into the view. You have to do this weird `_` syntax that SwiftUI hacks seem to love.
        _files = Query(filter: #Predicate<File> { file in
            return file.folder.persistentModelID == id
        }, sort: \.order)
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 12)
    ]
    
    var body: some View {
        Group {
            switch viewMode {
            case .grid:
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(files) { file in
                            GridFileCard(file: file)
                        }
                    }
                }
            case .list:
                List {
                    ForEach(files) { file in
                        ListFileCard(file: file)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(.plus) {
                    withAnimation {
                        let newFile = File(createdAt: .now, folder: folder, title: "Test File", shortDescription: "This is a small test document", color: ThemeColor.random, type: .localURL, url: URL(string: "https://google.com")!, bookmark: nil, source: "web", order: files.count)
                        modelContext.insert(newFile)
                    }
                }

                Menu("Filter & Sorting", systemImage: SFSymbol.line_3_horizontal_decrease.name) {
                    Picker(selection: $viewMode) {
                        Text("Grid")
                            .tag(FolderViewMode.grid)
                        Text("List")
                            .tag(FolderViewMode.list)
                    } label: {
                        EmptyView() // Quick hack to remove the section header that gets added for this entry.
                    }
                    .pickerStyle(.inline)
                    Divider()
                }
            }
        }
        .navigationTitle(folder.name)

    }
}

#Preview {
    // TODO: Figure out why the view is never populated with data
    @Previewable @State var folder = SampleDatabase.shared.sampleFolders.first!
    NavigationSplitView {
        
    } detail: {
        FolderView(folder: folder)
    }
    .modelContainer(SampleDatabase.shared.modelContainer)
}

