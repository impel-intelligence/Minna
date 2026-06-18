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
import OrderedCollections

struct FolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    @Environment(\.alertCenter) private var alertCenter

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
    
    @State var standardFileImporterPresented: Bool = false
    @State var selectedFiles: OrderedSet<File> = []
    @State var selectionAnchor: File? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 12)
    ]
    
    init(folder: Folder) {
        self.folder = folder
        let id = folder.persistentModelID

        // This is funky! For some reason there is now way to filter a query when it enters into the view. You have to do this weird `_` syntax that SwiftUI hacks seem to love.
        _files = Query(filter: #Predicate<File> { file in
            return file.folder.persistentModelID == id
        })
    }
    
    var body: some View {
        Group {
            switch viewMode {
            case .grid:
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(filteredFiles) { file in
                            GridFileCard(file: file)
                                .onTapGesture {
                                    tapGesture(for: file)
                                }
                                .contextMenu {
                                    itemContextMenu(for: file)
                                }
                                .overlay {
                                    if selectedFiles.contains(file) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(.blue.opacity(0.8), lineWidth: 3)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            case .list:
                List {
                    ForEach(filteredFiles) { file in
                        ListFileCard(file: file)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                tapGesture(for: file)
                            }
                            .contextMenu {
                                itemContextMenu(for: file)
                            }
                            .overlay {
                                if selectedFiles.contains(file) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(.blue.opacity(0.8), lineWidth: 3)
                                }
                            }
                    }
                }
            }
        }
        .standardFileImporter(
            presented: $standardFileImporterPresented,
            selectedFolder: folder,
            modelContext: modelContext,
            irisContext: irisContext
        )
        .toolbar {
            ToolbarItem {
                NotificationsViewButton()
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button("Send Notification") {
                    let notification = UserNotification(title: "This is a test notification", message: "Tesyt test ", actions: [
                        UserNotification.ActionOption(title: "Move", action: {
                            print("Move")
                        }),
                        UserNotification.ActionOption(title: "Ignore", action: {
                            print("Ignore")
                        })
                    ])
                    
                    alertCenter.post(notification)
                }
                Menu {
                    AddItemMenuButtons(presentLocalFilePicker: $standardFileImporterPresented)
                } label: {
                    Label {
                        Text("Add Content")
                    } icon: {
                        Image(.plus)
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
    
    private func tapGesture(for file: File) {
        // MARK: Selection Support (https://support.apple.com/guide/mac-help/select-items-mchlp1378/mac)
        
        // If we are not holding command, clear the previous selection
        if !NSEvent.modifierFlags.contains(.command) {
            selectedFiles.removeAll()
        }
        
        // Select multiple items that are adjacent
        if NSEvent.modifierFlags.contains(.shift), let selectionAnchor,
           let currentIndex = filteredFiles.firstIndex(of: file),
           let anchorIndex = filteredFiles.firstIndex(of: selectionAnchor) {
            let range: ClosedRange<Int> = currentIndex < anchorIndex ? currentIndex...anchorIndex : anchorIndex...currentIndex

            for file in filteredFiles[range] {
                selectedFiles.append(file)
            }
        } else {
            selectionAnchor = file
            selectedFiles.toggle(file)
        }
    }
    
    @ViewBuilder
    private func itemContextMenu(for file: File) -> some View {
        Button {
            
        } label: {
            Label("Rename", symbol: .pencil_line)
        }
        
        Button(role: .destructive) {
            modelContext.delete(file)
        } label: {
            Label("Delete", symbol: .trash)
        }

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
    .environment(AlertCenter.shared)
}
