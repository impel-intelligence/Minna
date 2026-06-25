//
//  FolderView.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SwiftData
import ViewStorage
import Collections
import SFSafeSymbols
import SentrySwift

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
    @Environment(\.alertCenter) private var alertCenter
    
    @Environment(\.openURL) private var openURL

    static let cardWidth: CGFloat = 150
    static let gridSpacing: CGFloat = 12
    
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
    }
    
    var body: some View {
        Group {
            switch viewMode {
            case .grid:
                gridBody
            case .list:
                listBody
            }
        }
        .frameReader { self.frame = $0 }
        .standardFileImporter(
            presented: $standardFileImporterPresented,
            selectedFolder: folder,
            modelContext: modelContext,
            irisContext: irisContext
        )
        .toolbar {
//            ToolbarItem {
//                NotificationsViewButton()
//                Button("Send Notification") {
//                    let notification = UserNotification(title: "This is a test notification", message: "Tesyt test ", actions: [
//                        UserNotification.ActionOption(title: "Move", action: {
//                            print("Move")
//                        }),
//                        UserNotification.ActionOption(title: "Ignore", action: {
//                            print("Ignore")
//                        })
//                    ])
//                    
//                    alertCenter.post(notification)
//                }
//            }

            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    AddItemMenuButtons(presentLocalFilePicker: $standardFileImporterPresented)
                } label: {
                    Label {
                        Text("Add Content")
                    } icon: {
                        Image(systemSymbol: .plus)
                    }
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
        ScrollView {
            VStack {
                ForEach(filteredFiles) { file in
                    OpaqueFileCard(file: file, isEditingText: $editingFileText, viewMode: $viewMode, selectedFiles: $selectedFiles)
                        .onTapGesture {
                            tapGesture(for: file)
                        }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
        }
        .scrollContentBackground(.hidden)

    }
    
    var gridBody: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(filteredFiles) { file in
                    OpaqueFileCard(file: file, isEditingText: $editingFileText, viewMode: $viewMode, selectedFiles: $selectedFiles)
                        .onTapGesture {
                            tapGesture(for: file)
                        }
                }
            }
            .padding(.vertical, 8)
        }
        .scrollContentBackground(.hidden)
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
    
    private func delete(_ file: File) {
        modelContext.delete(file)

        do {
            try irisContext.delete(file)
        } catch {
            SentrySDK.capture(error: error)
            print("Failed to delete Iris Document \(error)")
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
