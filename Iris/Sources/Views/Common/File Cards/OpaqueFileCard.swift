//
//  OpaqueFileCard.swift
//  Iris
//
//  Created by Taylor Lineman on 6/22/26.
//

import SwiftUI
import Collections
import SFSafeSymbols
import SentrySwift

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
    
    let file: File
    
    @FocusState private var focusedField: CardEditField?
    
    @Binding var isEditingText: Bool

    @Binding var viewMode: FolderViewMode
    @Binding var selectedFiles: OrderedSet<File>
    
    @State var editingTitle: Bool = false
    @State var editingDescription: Bool = false
    
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
        }
        .onChange(of: editingDescription) { _, newValue in
            isEditingText = newValue
        }
    }
    
    @ViewBuilder
    private func itemContextMenu(for file: File) -> some View {
        Button {
            let filesToOpen = selectedFiles.isEmpty ? [file] : selectedFiles
            
            for file in filesToOpen {
                open(file)
            }
        } label: {
            Label(selectedFiles.count <= 1 ? "Open Original" : "Open Originals", systemSymbol: .arrowUpRight)
        }
        
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
                FrontendDatabase.shared.queueDescriptionUpdate(for: file)
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
                if selectedFiles.isEmpty {
                    delete(file)
                } else {
                    for selectedFile in selectedFiles {
                        delete(selectedFile)
                    }
                    selectedFiles.removeAll()
                }
            }
        } label: {
            Label(selectedFiles.isEmpty ? "Delete" : "Delete Selected", systemSymbol: .trash)
        }
        .foregroundStyle(.red)
    }
    
    private func move(file: File, to newFolder: Folder) {
        file.folder = newFolder
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
    
    private func open(_ file: File) {
        // Check if we are a file URL and have bookmark data. Otherwise, try and open like a webpage.
        guard file.url.isFileURL, file.bookmark != nil else {
            openURL(file.url)
            return
        }
        
        do {
            let url = try file.securityScopedURL()
            guard url.startAccessingSecurityScopedResource() else { return }
            
            NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                url.stopAccessingSecurityScopedResource()
                if let error { print("Failed to open original \(url): \(error)") }
            }
        } catch {
            SentrySDK.capture(error: error)
            print("Failed to open url: \(error) - \(file.url)")
        }
    }
}

#Preview {
    @Previewable @State var selectedFiles: OrderedSet<File> = []
    @Previewable @State var file: File = File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol(SFSymbol.textPage.rawValue), color: .mint)), title: "This-is-a-long-name-with-no-spaces", shortDescription: "This is a quick description of this file and the content it contains. This is a quick description of this file and the content it contains. This is a quick description of this file and the content it contains.", color: .random, type: .webpage, url: URL(string: "https://google.com")!, bookmark: nil, source: "google.com")
    
    OpaqueFileCard(file: file, isEditingText: .constant(false), viewMode: .constant(.grid), selectedFiles: $selectedFiles)
        .modelContext(SampleDatabase.shared.context)
    OpaqueFileCard(file: file, isEditingText: .constant(false), viewMode: .constant(.list), selectedFiles: $selectedFiles)
        .modelContext(SampleDatabase.shared.context)
}
