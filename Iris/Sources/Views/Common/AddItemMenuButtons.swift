//
//  AddItemMenu.swift
//  Iris
//
//  Created by Taylor Lineman on 6/16/26.
//

import SwiftUI
import UniformTypeIdentifiers
import Digester
import SwiftData

enum IrisFileDialog {
    static let main: String = "com.tryiris.file.dialog.main"
}

struct AddItemMenuButtons: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var presentLocalFilePicker: Bool

    var body: some View {
        Group {
            Button {
                presentLocalFilePicker.toggle()
            } label: {
                Label("Add a local file", symbol: .laptopcomputer)
            }
            .keyboardShortcut("N", modifiers: [.command])
            Button {
                
            } label: {
                Label("Add a file from the cloud", symbol: .custom("custom.cloud.badge.plus"))
            }
            .keyboardShortcut("N", modifiers: [.shift, .command])
            Button {
                
            } label: {
                Label("Start a recording", symbol: .mic)
            }
            .keyboardShortcut("R", modifiers: [.shift, .command])
        }
    }
}

extension View {
    func standardFileImporter(presented: Binding<Bool>, selectedFolder: Folder?, modelContext: ModelContext) -> some View {
        self
            .fileDialogMessage("Pick a file to add to Iris.")
            .fileDialogCustomizationID(IrisFileDialog.main)
            .fileImporter(isPresented: presented, allowedContentTypes: DigesterFactory.availableUniformTypes + [.directory, .folder], allowsMultipleSelection: true) { result in

                do {
                    var folder: Folder
                    
                    if let selectedFolder {
                        folder = selectedFolder
                    } else {
                        // Capture the unfilled UUID so the predicate operates (it needs local state)
                        let unfilledUUID = Database.shared.unfilledFolderUUID
                        let descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.uuid == unfilledUUID })
                        let folders = try modelContext.fetch(descriptor)
                        guard let unfilledFolder = folders.first else { return }
                        folder = unfilledFolder
                    }

                    let files = try result.get()
                    
                    for file in files {
                        let gotAccess = file.startAccessingSecurityScopedResource()
                        guard gotAccess else { return }
                        
                        do {
                            // URL may be a directory, so this can return many urls.
                            let files = try FileFactory.files(from: file, in: folder)
                            
                            for file in files {
                                modelContext.insert(file)
                            }
                            
                            // DigesterFactory.digester(for: url)
                            
                        } catch {
                            print("Failed to create file for \(file): \(error)")
                        }
                        
                        file.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    print(error)
                }
                
            }

    }
}
