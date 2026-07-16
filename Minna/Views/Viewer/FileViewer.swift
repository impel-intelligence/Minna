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

struct FileViewer: View {
    let file: File
    @State var previewURL: URL?
    
    var body: some View {
        HStack {
            content
            
            sidebar
        }
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
    }
    
    var content: some View {
        Group {
            if let previewURL {
                QLPreview(url: previewURL)
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

struct QLPreview: NSViewRepresentable {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func makeNSView(context: Context) -> QLPreviewView {
        let previewView = QLPreviewView(frame: .zero, style: .normal) ?? QLPreviewView()
        previewView.previewItem = url as any QLPreviewItem
        return previewView
    }
    
    func updateNSView(_ previewView: QLPreviewView, context: Context) {
        previewView.previewItem = url as any QLPreviewItem
    }
}
