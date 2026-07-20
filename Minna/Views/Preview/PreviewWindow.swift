//
//  PreviewWindow.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//

import SwiftUI
import SwiftData
import DatabaseSchema

/// A small conversion layer between a URL and a File from the frontend database.
struct PreviewWindow: View {
    static let windowID = "file-details"
    
    @Environment(\.dismissWindow) var dismissWindow
    
    var file: File?
    @State var fileLoadError: Error?
    @State var windowParameters: OpenFileParameters?
    
    @State var highlightedExcerpts: [Int] = []
    
    init(parameters: OpenFileAction, context: ModelContext) {
        let id = parameters.id
        var descriptor = FetchDescriptor<File>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        
        do {
            self.file = try context.fetch(descriptor).first
        } catch {
            fileLoadError = error
        }
    }
    
    var body: some View {
        if let file {
            PreviewView(file: file, highlightedExcerpts: $highlightedExcerpts)
                .onReceive(NotificationCenter.default.publisher(for: PreviewWindowParameterStore.parametersChanged)) { notification in
                    guard let action = notification.object as? OpenFileAction else { return }
                    guard action.id == file.id else { return }
                    windowParameters = PreviewWindowParameterStore.shared.consumeParameters(for: action)
                    highlightedExcerpts = windowParameters?.excertps ?? []
                }
                .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { notification in
                    guard let userInfo = notification.userInfo else { return }
                    
                    // Get the set of deleted object identifiers
                    if let deleted = userInfo["deleted"] as? Set<PersistentIdentifier> {
                        // Check if the file was deleted
                        if deleted.contains(file.persistentModelID) {
                            dismissWindow()
                        }
                    }
                }
        } else if let fileLoadError {
            ContentUnavailableView(fileLoadError.localizedDescription, systemImage: "pc")
        } else {
            ContentUnavailableView("Unkown Error", systemImage: "pc")
        }
        
    }
}
