//
//  FileWindow.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//

import SwiftUI
import SwiftData
import DatabaseSchema

struct OpenFileParameters: Identifiable, Codable, Hashable {
    let id: PersistentIdentifier
}

/// A small conversion layer between a URL and a File from the frontend database.
struct FileWindow: View {
    static let windowID = "file-details"
    
    var file: File?
    @State var fileLoadError: Error?
    
    init(parameters: OpenFileParameters, context: ModelContext) {
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
            FileViewer(file: file)
        } else if let fileLoadError {
            ContentUnavailableView(fileLoadError.localizedDescription, systemImage: "pc")
        } else {
            ContentUnavailableView("Unkown Error", systemImage: "pc")
        }
    }
}
