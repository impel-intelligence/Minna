//
//  AddItemMenu.swift
//  Iris
//
//  Created by Taylor Lineman on 6/16/26.
//

import SwiftUI
import UniformTypeIdentifiers
import Digester

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
    func standardFileImporter(presented: Binding<Bool>) -> some View {
        self
            .fileDialogMessage("Pick a file to add to Iris.")
            .fileDialogCustomizationID(IrisFileDialog.main)
            .fileImporter(isPresented: presented, allowedContentTypes: DigesterFactory.availableUniformTypes, allowsMultipleSelection: true) { result in
                do {
                    let urls = try result.get()
                    
                    for url in urls {
                        
                        //                    DigesterFactory.digester(for: url)
                    }
                } catch {
                    print("Failed ")
                }
            }

    }
}
