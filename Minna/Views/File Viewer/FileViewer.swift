//
//  FileViewer.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-07-16
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
    @State private var failedToScopeErorr: Error?
    
    @Binding var highlightedExcerpts: [Int]
    @State private var sidebarOpen: Bool = false
    
    var body: some View {
        ZStack {
            // HACK: This does the job of container background without making the entire toolbar a solid color.
            file.color.background.ignoresSafeArea() // Used to fill the background color.
            ScrollView { } // A scroll view just existing toggles the toolbar to be transparent.

            content
                .ignoresSafeArea(.container, edges: .top)
                .inspector(isPresented: $sidebarOpen) {
                    sidebar
                        .inspectorColumnWidth(min: 250, ideal: 300, max: 600)
                        .presentationBackground(.clear)
                        .scrollContentBackground(.hidden)
                }

        }
        .navigationTitle(file.title)
        .animation(.bouncy, value: sidebarOpen)
        .onAppear {
            do {
                previewURL = try file.securityScopedURL()
            } catch {
                failedToScopeErorr = error
                print("Failed to create scoped url: \(error)")
            }
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
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    sidebarOpen.toggle()
                } label: {
                    Label {
                        Text("Ask Minna")
                    } icon: {
                        Image(.impelLogo)
                            .resizable()
                            .frame(width: 19, height: 19)
                    }
                }
                .labelStyle(.titleAndIcon)
            }
        }
    }
    
    var content: some View {
        Group {
            if let previewURL {
                LookAtMe(url: previewURL, color: file.color.background)
            } else if let failedToScopeErorr {
                ContentUnavailableView("Failed to open file", systemSymbol: .pc, description: Text(failedToScopeErorr.localizedDescription))
            } else {
                ContentUnavailableView("Unkown Error", systemSymbol: .pc)
            }
        }
    }
    
    var sidebar: some View {
        FileChat(file: file)
            .presentationBackground(.clear)
            .scrollContentBackground(.hidden)
    }
}

#Preview {
    FileViewer(file: SampleDatabase.shared.sampleFiles[0], highlightedExcerpts: .constant([]))
        .modelContainer(SampleDatabase.shared.modelContainer)
}
