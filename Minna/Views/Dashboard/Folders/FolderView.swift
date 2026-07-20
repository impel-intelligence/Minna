//
//  FolderView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SwiftData
import ViewStorage
import OrderedCollections
import SFSafeSymbols
import SentrySwift
import DatabaseSchema

enum ArrowDirection {
    case up
    case down
    case left
    case right
    
    init?(from equivalent: KeyEquivalent) {
        switch equivalent {
        case .leftArrow:
            self = .left
        case .rightArrow:
            self = .right
        case .upArrow:
            self = .up
        case .downArrow:
            self = .down
        default:
            return nil
        }
    }
}

// TODO: Investigate Focus States
struct FolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    @Environment(\.database) var database
    @Environment(\.openURL) private var openURL
    @Environment(\.router) private var navigationRouter

    static let cardWidth: CGFloat = 150
    static let gridSpacing: CGFloat = 12
    
    let folder: Folder

    // WARN: Do not edit this query, its actual value is set in the initializer
    @Query private var files: [File]
    
    // SwiftData does not support filtering by custom enums within a query. This in-memory filtering is required. Swift Data also does not support dynamic sorts... So we are doing that in memory as well.
    var filteredFiles: [File] {
        files.filter { contentTypes.contains($0.type) }.sorted(by: sortMode.sortFunction(lhs:rhs:))
    }
    
    // WARN: Do not edit this query, its actual value is set in the initializer
    @Query private var folders: [Folder]

    @ViewStorage("viewMode", path: \Self.folder.uuid.uuidString) var viewMode: FolderViewMode = .grid
    @ViewStorage("contentTypes", path: \Self.folder.uuid.uuidString) var contentTypes: Set<ContentType> = Set(ContentType.allCases)
    @ViewStorage("sortMode", path: \Self.folder.uuid.uuidString) var sortMode: FolderViewSort = .mostRecent
    
    @State var standardFileImporterPresented: Bool = false
    @State var selectedFiles: OrderedSet<File> = []
    @State var selectionAnchor: File?
    @State var frame: CGRect = .zero
    
    @State var editingFileText: Bool = false

    @State var showDeleteConfirmation: Bool = false

    @FocusState private var isFocused: Bool

    let columns = [
        GridItem(.adaptive(minimum: FolderView.cardWidth, maximum: FolderView.cardWidth), spacing: FolderView.gridSpacing)
    ]
    
    init(folder: Folder) {
        self.folder = folder
        let id = folder.persistentModelID

        // This is funky! For some reason there is now way to filter a query when it enters into the view. You have to do this weird `_` syntax that SwiftUI hacks seem to love.
        _files = Query(filter: #Predicate<File> { file in
            return file.folder.persistentModelID == id
        })
        
        _folders = Query(filter: #Predicate<Folder> { folder in
            return folder.parent?.persistentModelID == id
        }, sort: \.name)
    }
    
    var body: some View {
        ScrollView {
            if !folders.isEmpty {
                VStack {
                    HStack {
                        Text("Folders")
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(folders) { folder in
                                FolderCard(folder: folder)
                                    .accessibilityAddTraits(.isLink)
                                    .onTapGesture {
                                        navigationRouter.push(folder)
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
            
            switch viewMode {
            case .grid:
                gridBody
            case .list:
                listBody
            }
        }
        .frameReader(in: .local) { self.frame = $0 }
        .standardFileImporter(
            presented: $standardFileImporterPresented,
            selectedFolder: folder,
            modelContext: modelContext,
            irisContext: irisContext,
            database: database
        )
        .toolbar {
            FolderViewToolbar(
                viewMode: $viewMode,
                contentTypes: $contentTypes,
                sortMode: $sortMode,
                standardFileImporterPresented: $standardFileImporterPresented
            )
        }
        .navigationTitle(folder.name, image: folder.icon.image())
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
//        .onChange(of: isFocused) { _, focused in
//            // When focus moves to this view, check to see if a mouse button was pressed. If that is the case, this view was opened by the mouse so we don't need to start focus tracking.
//            guard NSEvent.pressedMouseButtons == 0 else { return }
//
//            // If the focus was gained through the keyboard (e.g. tab from the navigation list), select the first item to allow for instant keyboard navigation.s
//            if focused, selectedFiles.isEmpty, let firstFile = filteredFiles.first {
//                selectedFiles.append(firstFile)
//                selectionAnchor = firstFile
//            }
//        }
        .onKeyPress { keyPress in
            guard !self.editingFileText else { return .ignored }
            
            if keyPress.characters == "a" && keyPress.modifiers == .command {
                selectedFiles.append(contentsOf: filteredFiles)
                return .handled
            } else if keyPress.key == .escape {
                selectedFiles.removeAll()
                return .handled
            } else if let direction = ArrowDirection(from: keyPress.key) {
                // If we were able to construct an arrow direction, the user moved using the arrow keys.
                return moveCursor(direction: direction, modifiers: keyPress.modifiers)
            }
                        
            return .ignored
        }
        .onDeleteCommand {
            guard !self.editingFileText else { return }
            guard !selectedFiles.isEmpty else { return }
            showDeleteConfirmation = true
        }
        .alert("Delete selected files?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                for file in selectedFiles {
                    delete(file)
                }
            }
        }
    }
    
    var listBody: some View {
        VStack {
            ForEach(filteredFiles) { file in
                OpaqueFileCard(file: file, isEditingText: $editingFileText, viewMode: $viewMode, selectedFiles: $selectedFiles)
                    .simultaneousGesture(TapGesture(count: 1).onEnded {
                        tapGesture(for: file)
                    })
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
    }
    
    var gridBody: some View {
        LazyVGrid(columns: columns) {
            ForEach(filteredFiles) { file in
                OpaqueFileCard(file: file, isEditingText: $editingFileText, viewMode: $viewMode, selectedFiles: $selectedFiles)
                    .simultaneousGesture(TapGesture(count: 1).onEnded {
                        tapGesture(for: file)
                    })
            }
        }
        .padding(.vertical, 8)
    }
    
    
    private func moveCursor(direction: ArrowDirection, modifiers: EventModifiers) -> KeyPress.Result {
        if selectedFiles.isEmpty, let firstFile = filteredFiles.first {
            selectedFiles.append(firstFile)
            selectionAnchor = firstFile
            return .handled
        } else if let currentAnchor = selectionAnchor,
                  let currentIndex = filteredFiles.firstIndex(of: currentAnchor) {
            func moveSelection(by offset: Int) -> KeyPress.Result {
                let nextIndex = currentIndex + offset
                guard filteredFiles.indices.contains(nextIndex) else { return .ignored }
                let nextFile = filteredFiles[nextIndex]

                // If we are not holding command, clear the previous selection
                if !(NSEvent.modifierFlags.contains(.command) || NSEvent.modifierFlags.contains(.shift)) {
                    selectedFiles.removeAll()
                }

                selectionAnchor = nextFile
                selectedFiles.append(nextFile)

                return .ignored
            }

            let itemsInGrid = Int(frame.width / (FolderView.cardWidth + (FolderView.gridSpacing / 2)))

            switch direction {
            case .up:
                return moveSelection(by: viewMode == .grid ? -itemsInGrid : 1)
            case .down:
                return moveSelection(by: viewMode == .grid ? itemsInGrid : -1)
            case .left:
                return moveSelection(by: -1)
            case .right:
                return moveSelection(by: 1)
            }
        }
        
        return .ignored
    }
    
    private func tapGesture(for file: File) {
        // MARK: Selection Support (https://support.apple.com/guide/mac-help/select-items-mchlp1378/mac)
        
        // Select multiple items that are adjacent
        if NSEvent.modifierFlags.contains(.shift), let selectionAnchor,
           let currentIndex = filteredFiles.firstIndex(of: file),
           let anchorIndex = filteredFiles.firstIndex(of: selectionAnchor) {
            let range: ClosedRange<Int> = currentIndex < anchorIndex ? currentIndex...anchorIndex : anchorIndex...currentIndex

            for file in filteredFiles[range] {
                selectedFiles.append(file)
            }
        } else {
            // If we are not holding command, clear all files other than the current one
            if !NSEvent.modifierFlags.contains(.command) {
                selectedFiles.removeAll(where: { $0 != file })
            }
            
            selectionAnchor = file
            selectedFiles.toggle(file)
        }
    }
    
    /// Deletes a file from the SwiftData store and the Iris search index.
    /// A chat file's `chat` relationship is loaded lazily, so it is normally an
    /// unfaulted `_FullFutureBackingData` future. Deleting the file fires the
    /// `File.chat` `.cascade` rule, and SwiftData crashes in `ModelSnapshot`
    /// ("Unexpected backing data for snapshot creation: _FullFutureBackingData")
    /// while snapshotting that un-materialized chat. Reading a stored property
    /// first forces the chat to fault into concrete backing data, after which the
    /// cascade delete succeeds. Verified against an in-memory store reproduction.
    ///
    /// By realizing components of the chat, SwiftData is forced to load the model,
    /// which allows it to properly delete the chat.
    ///
    /// - Fix Authored by: Claude Opus 4.8 (Anthropic)
    private func delete(_ file: File) {
        // Fault the related chat into memory so the cascade delete can snapshot it.
        if let chat = file.chat {
            _ = chat.uuid
        }

        modelContext.delete(file)

        do {
            try irisContext.delete(file)
        } catch {
            SentrySDK.capture(error: error)
            print("Failed to delete Iris Document \(error)")
        }
    }
}

private struct FolderViewToolbar: ToolbarContent {
    @Binding var viewMode: FolderViewMode
    @Binding var contentTypes: Set<ContentType>
    @Binding var sortMode: FolderViewSort
    
    @Binding var standardFileImporterPresented: Bool
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                AddItemMenuButtons(presentLocalFilePicker: $standardFileImporterPresented)
            } label: {
                Label("Add Content", systemSymbol: .plus)
            }
            
            Menu("Filter & Sorting", systemImage: SFSymbol.line3HorizontalDecrease.rawValue) {
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
}

#Preview {
    // TODO: Figure out why the view is never populated with data
    @Previewable @State var folder = SampleDatabase.shared.sampleFolders.first!
    NavigationSplitView {
        
    } detail: {
        FolderView(folder: folder)
    }
    .modelContainer(SampleDatabase.shared.modelContainer)
    .database(SampleDatabase.shared)
}
