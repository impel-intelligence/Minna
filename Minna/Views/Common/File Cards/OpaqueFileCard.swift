//
//  OpaqueFileCard.swift
//  Minna
//
//  Created by Taylor Lineman on 6/22/26.
//

import SwiftUI
import OrderedCollections
import SFSafeSymbols
import SentrySwift
import SwiftData
import DatabaseSchema
import Logging
import IrisSearch

enum CardEditField: Hashable {
    case title
    case description
    case none
}

/// A file card that has the distinction between grid or list abstracted. Provides a stable context menu between grid and list cards + the ability to track editing state.
struct OpaqueFileCard: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.openURL) var openURL
    @Environment(\.database) var database
    @Environment(\.router) var navigationRouter
    @Environment(\.openWindow) var openWindow
    
    let file: File
    var enableEditing: Bool = true
    
    @FocusState private var focusedField: CardEditField?
    
    @Binding var isEditingText: Bool

    @Binding var viewMode: FolderViewMode
    @Binding var selectedFiles: OrderedSet<File>
    
    @State var editingTitle: Bool = false
    @State var editingDescription: Bool = false
    
    @State var metadataChangeTask: Task<Void, Never>?

    var body: some View {
        Group {
            switch viewMode {
            case .grid:
                GridFileCard(file: file, editingTitle: $editingTitle, editingDescription: $editingDescription, focusedField: _focusedField)
            case .list:
                ListFileCard(file: file, editingTitle: $editingTitle, editingDescription: $editingDescription, focusedField: _focusedField)
            }
        }
        .focusable(true, interactions: .activate)
        .contextMenu {
            itemContextMenu(for: file)
        }
        .overlay {
            if selectedFiles.contains(file) {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.blue.opacity(0.8), lineWidth: 3)
            }
        }
        .onChange(of: editingTitle) { _, newValue in
            isEditingText = newValue
            file.title = file.title.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !newValue {
                launchMetadataTask()
            }
        }
        .onChange(of: editingDescription) { _, newValue in
            isEditingText = newValue
            file.shortDescription = file.shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !newValue {
                launchMetadataTask()
            }
        }
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            open(file)
        })
    }
    
    private func launchMetadataTask() {
        metadataChangeTask?.cancel()
                    
        metadataChangeTask = Task(priority: .high) {
            // Debounce: wait 20ms before searching
            try? await Task.sleep(for: Duration.milliseconds(50))
            
            // Check if cancelled during wait
            guard !Task.isCancelled else { return }
            
            do {
                try await irisContext.database.updateDocumentMetadata(uuid: file.uuid, title: file.title, description: file.shortDescription)
            } catch {
                Log.logger.error("Failed to set document metadata", error: error, metadata: ["uuid": "\(file.uuid)"])
                SentrySDK.capture(error: error)
            }
        }

    }
    
    @ViewBuilder
    private func itemContextMenu(for file: File) -> some View {
        Button {
            let filesToOpen = selectedFiles.isEmpty ? [file] : selectedFiles
            
            for file in filesToOpen {
                openOriginal(file)
            }
        } label: {
            Label(selectedFiles.count <= 1 ? "Open Original" : "Open Originals", systemSymbol: .arrowUpRight)
        }
        
        if enableEditing {
            // TODO: Support multi-rename, look at macOS multi-rename for inspo
            Button {
                editingTitle.toggle()
                focusedField = .title
            } label: {
                Label(editingTitle ? "Stop Rename" : "Rename", systemSymbol: .pencilLine)
            }
            
            Button {
                editingDescription.toggle()
                focusedField = .description
            } label: {
                Label(editingDescription ? "Stop Editing" : "Edit Description", systemSymbol: .pencilLine)
            }
            
            Button {
                let filesToGenerate = selectedFiles.isEmpty ? [file] : selectedFiles
                
                for file in filesToGenerate {
                    database.queueDescriptionUpdate(for: file)
                }
            } label: {
                Label(selectedFiles.count <= 1 ? "Generate Description" : "Generate Descriptions", systemSymbol: .sparkles)
            }
            
            Menu {
                ForEach(ThemeColor.allCases) { theme in
                    Button {
                        let filesToChange = selectedFiles.isEmpty ? [file] : selectedFiles
                        
                        for file in filesToChange {
                            file.color = theme
                            file.chat?.theme = theme
                        }
                    } label: {
                        Label(theme.description, systemSymbol: .circleFill)
                            .foregroundStyle(theme.background)
                    }
                }
            } label: {
                Label("Change Color", systemSymbol: .paintpalette)
                
            }
            
            FolderMenu { newFolder in
                withAnimation {
                    let filesToMove = selectedFiles.isEmpty ? [file] : selectedFiles
                    
                    for file in filesToMove {
                        move(file: file, to: newFolder)
                    }
                }
            } label: {
                Label(selectedFiles.count <= 1 ? "Move" : "Move Selected", systemSymbol: .folder)
            }
            
            Divider()
            
            Button(role: .destructive) {
                withAnimation {
                    do {
                        try modelContext.transaction {
                            if selectedFiles.isEmpty {
                                delete(file)
                            } else {
                                for selectedFile in selectedFiles {
                                    delete(selectedFile)
                                }
                                selectedFiles.removeAll()
                            }
                        }
                    } catch {
                        Log.logger.error("Failed to delete files", error: error)
                    }
                }
            } label: {
                Label(selectedFiles.isEmpty ? "Delete" : "Delete Selected", systemSymbol: .trash)
            }
            .foregroundStyle(.red)
        }
    }
    
    private func move(file: File, to newFolder: Folder) {
        file.folder = newFolder
    }
    
    /// Deletes a file from the SwiftData store and the Iris search index.
    ///
    /// The related `chat` is faulted into memory first: deleting a chat file fires
    /// the `File.chat` `.cascade` rule, and SwiftData crashes in `ModelSnapshot`
    /// while snapshotting an un-materialized `_FullFutureBackingData` chat. See
    /// ``FolderView/delete(_:)`` for the full explanation.
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
            Log.logger.error("Failed to delete Iris Document \(file.uuid)", error: error)
        }
    }
    
    private func open(_ file: File) {
        if file.type == .askMinna, let chat = file.chat {
            navigationRouter.push(chat)
        } else {
            openWindow(id: WindowID.preview, value: OpenFileAction(id: file.id))
        }
    }
    
    private func openOriginal(_ file: File) {
        do {
            try file.openOriginal(openURL: openURL)
        } catch {
            SentrySDK.capture(error: error)
            Log.logger.error("Failed to open url \(file.url)", error: error)
        }
    }
}

#Preview {
    @Previewable @State var selectedFiles: OrderedSet<File> = []
    @Previewable @State var file: File = File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol(SFSymbol.textPage.rawValue), color: .mint)), title: "This-is-a-long-name-with-no-spaces", shortDescription: "This is a quick description of this file and the content it contains. This is a quick description of this file and the content it contains. This is a quick description of this file and the content it contains.", color: .random, type: .webpage, url: URL(string: "https://google.com")!, bookmark: nil, source: "google.com")
    
    OpaqueFileCard(file: file, isEditingText: .constant(false), viewMode: .constant(.grid), selectedFiles: $selectedFiles)
        .modelContext(SampleDatabase.shared.context)
        .database(SampleDatabase.shared)
    OpaqueFileCard(file: file, isEditingText: .constant(false), viewMode: .constant(.list), selectedFiles: $selectedFiles)
        .modelContext(SampleDatabase.shared.context)
        .database(SampleDatabase.shared)
}
