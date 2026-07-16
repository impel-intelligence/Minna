//
//  FileViewer.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//

import SwiftUI
import DatabaseSchema
import SwiftData
import QuickLookUI
import LookAtMe
import SFSafeSymbols

struct FileViewer: View {
    @Environment(\.openURL) var openURL
    
    let file: File
    @State var previewURL: URL?
    
    var body: some View {
        ZStack {
            // HACK: This does the job of container background without making the entire toolbar a solid color.
            file.color.background.ignoresSafeArea() // Used to fill the background color.
            ScrollView { } // A scroll view just existing toggles the toolbar to be transparent.

            HStack {
                content
                    .ignoresSafeArea(.container, edges: .top)
                
                sidebar
            }
        }
        .navigationTitle(file.title)
        .onAppear {
            do {
                let scopedURL = try file.securityScopedURL()
                if scopedURL.startAccessingSecurityScopedResource() {
                    previewURL = scopedURL
                }
            } catch {
                print("Failed to create scoped url: \(error)")
            }
        }
        .onDisappear {
            try? file.securityScopedURL().stopAccessingSecurityScopedResource()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    do {
                        try file.openOriginal(openURL: openURL)
                    } catch {
                        print("Failed to open file: \(error)")
                    }
                } label: {
                    Label("Open Original", systemSymbol: .arrowUpForward)
                }
                .labelStyle(.titleAndIcon)
            }
        }
    }
    
    var content: some View {
        Group {
            if let previewURL {
                LookAtMe(url: previewURL, color: file.color.background)
            } else {
                Text("Failed to load")
            }
        }
    }
    
    var sidebar: some View {
        Text("Sidebar")
    }
}

#Preview {
    FileViewer(file: SampleDatabase.shared.sampleFiles[0])
        .modelContainer(SampleDatabase.shared.modelContainer)
}
