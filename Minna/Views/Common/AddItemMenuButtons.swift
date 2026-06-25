//
//  AddItemMenu.swift
//  Minna
//
//  Created by Taylor Lineman on 6/16/26.
//

import SwiftUI
import UniformTypeIdentifiers
import Digester
import SwiftData
import SFSafeSymbols

enum MinnaFileDialog {
    static let main: String = "com.tryminna.minna.dialog.main"
}

struct AddItemMenuButtons: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var presentLocalFilePicker: Bool

    var body: some View {
        Group {
            Button {
                presentLocalFilePicker.toggle()
            } label: {
                Label("Add a local file", systemSymbol: .laptopcomputer)
            }
            .keyboardShortcut("N", modifiers: [.command])
            Button {
                
            } label: {
                Label("Add a file from the cloud", image: "cloud.badge.plus")
            }
            .keyboardShortcut("N", modifiers: [.shift, .command])
            Button {
                
            } label: {
                Label("Start a recording", systemSymbol: .microbe)
            }
            .keyboardShortcut("R", modifiers: [.shift, .command])
        }
    }
}
