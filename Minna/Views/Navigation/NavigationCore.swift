//
//  NavigationCore.swift
//  Minna
//
//  Created by Taylor Lineman on 6/11/26.
//

import SwiftData
import SwiftUI
import SFSafeSymbols
import SentrySwift
import DatabaseSchema
import Logging

public struct NavigationCore: View {
    @Environment(\.undoManager) private var undoManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    @Environment(\.database) private var database
    @Environment(\.openWindow) var openWindow
    
    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \.order) private var folders: [Folder]

    @AppStorage("knowledgeExpanded") var knowledgeExpanded: Bool = true
    @AppStorage("connectionsExpanded") var connectionsExpanded: Bool = true

    @State var navigationRouter: NavigationRouter = NavigationRouter()
    
    @State var addFolderRequest: AddFolderRequest?
    
    @State var presentAppleIntelligenceAlert: Bool = false
    @State var presentUnknownErrorAlert: Bool = false
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $navigationRouter.selectedTab) {
                SearchStartupView.label
                    .tag(NavigationDestination.search)

                RecentsView.label
                    .tag(NavigationDestination.recents)

                Section("Knowledge Base", isExpanded: $knowledgeExpanded) {
                    ForEach(folders) { folder in
                        FolderRow(folder: folder, addFolder: addFolder)
                    }
                    .onMove { source, destination in
                        FolderRow.reorder(folders, from: source, to: destination)
                    }
                }

                Section("Connections", isExpanded: $connectionsExpanded) {}
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button {
                        addFolder(in: nil)
                    } label: {
                        Label("Add Item", systemSymbol: .plus)
                    }
                    .accessibilityIdentifier("navigation.addItem")
                }
            }
        } detail: {
            NavigationStack(path: $navigationRouter.path) {
                Group {
                    switch navigationRouter.selectedTab {
                    case .search, nil:
                        SearchStartupView()
                    case .recents:
                        RecentsView()
                    case .folder(let folder):
                        FolderView(folder: folder)
                            .id(folder.uuid)
                    }
                }
                .environment(navigationRouter)
                .navigationDestination(for: Folder.self) { folder in
                    FolderView(folder: folder)
                        .id(folder.uuid)
                        .environment(navigationRouter)
                }
                .navigationDestination(for: Chat.self) { chat in
                    AskMinnaView(chat: chat, viewMode: chat.transcript.isEmpty ? .startup : .chat)
                        .id(chat.uuid)
                        .environment(navigationRouter)
                }
            }
        }
        .router(navigationRouter)
        .onAppear {
            modelContext.undoManager = undoManager
            
            do {
                try irisContext.database
            } catch let error as IrisContextError {
                switch error {
                case .notConnected, .unknown:
                    presentUnknownErrorAlert = true
                case .noAppleIntelligence:
                    presentAppleIntelligenceAlert = true
                }
            } catch {
                presentUnknownErrorAlert = true
            }
        }
        .sheet(item: $addFolderRequest) { request in
            AddFolderForm(parentFolder: request.parent)
        }
        .task {
            // Start indexing all files that did not complete indexing.
            let descriptor = FetchDescriptor<File>(predicate: #Predicate<File> { file in
                !file.searchIndexed || !file.descriptionGenerated
            })
            
            guard let files = try? modelContext.fetch(descriptor) else { return }
            for file in files where !file.searchIndexed {
                do {
                    try irisContext.reIndex(file)
                } catch {
                    SentrySDK.capture(error: error)
                    Log.logger.error("Failed to re-index file", error: error, metadata: ["title": "\(file.title)", "uuid": "\(file.uuid.uuidString)"])
                    print("Failed to re-index file \(file.title) \(error)")
                }
            }
            
            for file in files where !file.descriptionGenerated {
                database.queueDescriptionUpdate(for: file)
            }
        }
        .onOpenURL { url in
            do {
                try URLHandler.handle(url, context: modelContext, router: navigationRouter, openWindow: openWindow)
            } catch {
                Log.logger.error("Failed to handle url", error: error, metadata: ["url": "\(url)"])
            }
        }
        .alert("Apple Intelligence is not Enabled", isPresented: $presentAppleIntelligenceAlert) {
            
        } message: {
            // TODO: Add better setup instructions.
            Text("Please enable Apple Intelligence in your device's settings to use Minna. After enabling Apple Intelligence in settings you will need to restart the application.")
        }
        .alert("An unknown error occurred while creating the Search Database", isPresented: $presentUnknownErrorAlert) {
            
        }
    }

    func addFolder(in folder: Folder?) {
        addFolderRequest = AddFolderRequest(parent: folder)
    }
    
}

#Preview {
    NavigationCore()
        .modelContainer(SampleDatabase.shared.modelContainer)
        .database(SampleDatabase.shared)
        .irisContext(IrisContext.notConnected)
}
