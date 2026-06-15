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

enum FolderViewMode: Int, CaseIterable, CustomStringConvertible, ViewStorable {
    case grid
    case list
    
    var description: String {
        switch self {
        case .grid:
            return "Grid"
        case .list:
            return "List"
        }
    }
}

enum FolderViewSort: Int, CaseIterable, CustomStringConvertible, ViewStorable {
    case mostRecent
    case leastRecent
    case az
    case za
    
    var description: String {
        switch self {
        case .mostRecent:
            return "Most Recent"
        case .leastRecent:
            return "Least Recent"
        case .az:
            return "A-Z"
        case .za:
            return "Z-A"
        }
    }
    
    var sortDescriptor: SortDescriptor<File> {
        switch self {
        case .mostRecent:
            return SortDescriptor(\.createdAt, order: .forward)
        case .leastRecent:
            return SortDescriptor(\.createdAt, order: .reverse)
        case .az:
            return SortDescriptor(\.title, order: .forward)
        case .za:
            return SortDescriptor(\.title, order: .reverse)
        }
    }
    
    func sortFunction(lhs: File, rhs: File) -> Bool {
        switch self {
        case .mostRecent:
            return lhs.createdAt.compare(rhs.createdAt) == .orderedDescending
        case .leastRecent:
            return lhs.createdAt.compare(rhs.createdAt) == .orderedAscending
        case .az:
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        case .za:
            return lhs.title.localizedCompare(rhs.title) == .orderedDescending
        }
    }
}

struct FolderView: View {
    @Environment(\.modelContext) private var modelContext
    
    let folder: Folder

    // WARN: Do not edit this query, its actual value is set in the initializer
    @Query private var files: [File]
    
    // SwiftData does not support filtering by custom enums within a query. This in-memory filtering is required. Swift Data also does not support dynamic sorts... So we are doing that in memory as well.
    var filteredFiles: [File] {
        files.filter { contentTypes.contains($0.type) }.sorted(by: sortMode.sortFunction(lhs:rhs:))
    }

    @ViewStorage("viewMode", path: \Self.folder.uuid.uuidString) var viewMode: FolderViewMode = .grid
    @ViewStorage("contentTypes", path: \Self.folder.uuid.uuidString) var contentTypes: Set<ContentType> = Set(ContentType.allCases)
    @ViewStorage("sortMode", path: \Self.folder.uuid.uuidString) var sortMode: FolderViewSort = .mostRecent
    
    init(folder: Folder) {
        self.folder = folder
        let id = folder.persistentModelID

        // This is funky! For some reason there is now way to filter a query when it enters into the view. You have to do this weird `_` syntax that SwiftUI hacks seem to love.
        _files = Query(filter: #Predicate<File> { file in
            return file.folder.persistentModelID == id
        })
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
                        ForEach(filteredFiles) { file in
                            GridFileCard(file: file)
                        }
                    }
                }
            case .list:
                List {
                    ForEach(filteredFiles) { file in
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
                        let newFile = File(createdAt: .now, folder: folder, title: "Test File \(files.count)", shortDescription: "This is a small test document", color: ThemeColor.random, type: .webpage, url: URL(string: "https://google.com")!, bookmark: nil, source: "web", order: files.count)
                        modelContext.insert(newFile)
                    }
                }

                Menu("Filter & Sorting", systemImage: SFSymbol.line_3_horizontal_decrease.name) {
                    Picker(selection: $viewMode) {
                        ForEach(FolderViewMode.allCases, id: \.rawValue) { mode in
                            Text(mode.description)
                                .tag(mode)

                        }
                    } label: {
                        EmptyView() // Quick hack to remove the section header that gets added for this entry.
                    }
                    .pickerStyle(.inline)
                    Divider()
                    MultiPicker(selection: $contentTypes) {
                        ForEach(ContentType.allCases, id: \.rawValue) { mode in
                            Text(mode.description)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    Divider()
                    Picker(selection: $sortMode) {
                        ForEach(FolderViewSort.allCases, id: \.rawValue) { mode in
                            Text(mode.description)
                                .tag(mode)
                        }
                    } label: {
                        EmptyView() // Quick hack to remove the section header that gets added for this entry.
                    }
                    .pickerStyle(.inline)
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

