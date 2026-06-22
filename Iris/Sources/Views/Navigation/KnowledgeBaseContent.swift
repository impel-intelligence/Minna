//
//  KnowledgeBaseContent.swift
//  Iris
//
//  Created by Taylor Lineman on 6/22/26.
//

import SwiftUI

struct KnowledgeBaseContent: View {
    @Environment(\.modelContext) private var modelContext
    var folders: [Folder]
    let addFolder: (Folder?) -> Void

    var body: some View {
        ForEach(folders) { folder in
            FolderRow(folder: folder, addFolder: addFolder)
        }
        .onMove { source, destination in
            FolderRow.reorder(folders, from: source, to: destination)
        }
    }
}
