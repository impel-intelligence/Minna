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

struct FolderContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    @Environment(\.database) var database
    @Environment(\.router) private var navigationRouter
    @Environment(\.openWindow) private var openWindow

    @Binding var selectedFile: File?
    let folder: Folder

    // WARN: Do not edit this query, its actual value is set in the initializer
    @Query private var files: [File]
    
    // SwiftData does not support filtering by custom enums within a query. This in-memory filtering is required. Swift Data also does not support dynamic sorts... So we are doing that in memory as well.
    var filteredFiles: [File] {
        files//.filter { contentTypes.contains($0.type) }.sorted(by: sortMode.sortFunction(lhs:rhs:))
    }
    
    init(selectedFile: Binding<File?>, folder: Folder) {
        self._selectedFile = selectedFile
        self.folder = folder
        
        let id = folder.persistentModelID

        // This is funky! For some reason there is now way to filter a query when it enters into the view. You have to do this weird `_` syntax that SwiftUI hacks seem to love.
        _files = Query(filter: #Predicate<File> { file in
            return file.folder.persistentModelID == id
        })
    }

    var body: some View {
        List(selection: $selectedFile) {
            ForEach(filteredFiles) { file in
                Text(file.title)
                    .tag(file)
            }
        }

    }
}

public struct NavigationCore: View {
    @Environment(\.undoManager) private var undoManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.irisContext) private var irisContext
    @Environment(\.database) private var database
    @Environment(\.openWindow) var openWindow
        
    @Query(filter: #Predicate<Folder> { $0.parent == nil }, sort: \.order) private var folders: [Folder]

    @AppStorage("knowledgeExpanded") var knowledgeExpanded: Bool = true
    @AppStorage("connectionsExpanded") var connectionsExpanded: Bool = true
    
    @AppStorage("hasShownDiscord") var hasShownDiscordSheet: Bool = false
    @State var presentingDiscordSheet: Bool = false

    @State var navigationRouter: NavigationRouter = NavigationRouter()
    
    @State var addFolderRequest: AddFolderRequest?
    
    @State var presentAppleIntelligenceAlert: Bool = false
    @State var presentUnknownErrorAlert: Bool = false
    @State var presentDatabaseInitializationError: Bool = false
    
    @State var isDroppingFile: Bool = false
    
    @State var selectedFolder: Folder?
    @State var selectedFile: File?
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedFolder) {
                ForEach(folders) { folder in
                    FolderRow(folder: folder, addFolder: addFolder)
                }
//                SearchStartupView.label
//                    .tag(NavigationDestination.search)

//                RecentsView.label
//                    .tag(NavigationDestination.recents)

//                Section("Knowledge Base", isExpanded: $knowledgeExpanded) {
//                    ForEach(folders) { folder in
////                        FolderRow(folder: folder, addFolder: addFolder)
//                    }
//                    .onMove { source, destination in
//                        FolderRow.reorder(folders, from: source, to: destination)
//                    }
//                }
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
        } content: {
            if let selectedFolder {
                FolderContent(selectedFile: $selectedFile, folder: selectedFolder)
            } else {
                Text("Select a folder")
            }
        } detail: {
            if let selectedFile {
                if selectedFile.type == .askMinna, let chat = selectedFile.chat {
                    AskMinnaView(chat: chat, viewMode: .chat)
                } else {
                    PreviewView(file: selectedFile, highlightedExcerpts: .constant([]))
                }
            } else {
                Text("Select a file")
            }
//            NavigationStack(path: $navigationRouter.path) {
//                Group {
//                    switch navigationRouter.selectedTab {
//                    case .search, nil:
//                        SearchStartupView()
////                    case .recents:
////                        RecentsView()
//                    case .folder(let folder):
//                        FolderView(folder: folder)
//                            .id(folder.uuid)
//                    }
//                }
//                .environment(navigationRouter)
//                .navigationDestination(for: Folder.self) { folder in
//                    FolderView(folder: folder)
//                        .id(folder.uuid)
//                        .environment(navigationRouter)
//                }
//                .navigationDestination(for: Chat.self) { chat in
//                    AskMinnaView(chat: chat, viewMode: chat.transcript.isEmpty ? .startup : .chat)
//                        .id(chat.uuid)
//                        .environment(navigationRouter)
//                }
//            }
        }
        .router(navigationRouter)
        .onChange(of: navigationRouter.selectedTab) { _, newValue in
            if case .folder(let folder) = newValue {
                navigationRouter.currentFolder = folder
            } else {
                navigationRouter.currentFolder = nil
            }
        }
        .onAppear {
            if !hasShownDiscordSheet {
                presentingDiscordSheet = true
                hasShownDiscordSheet = true
            }
            
            modelContext.undoManager = undoManager
            
            do {
                _ = try irisContext.database
            } catch let error as IrisContextError {
                switch error {
                case .notConnected, .unknown:
                    presentUnknownErrorAlert = true
                case .noAppleIntelligence:
                    presentAppleIntelligenceAlert = true
                case .noCoreML:
                    // TODO: Restart a download of the model
                    presentAppleIntelligenceAlert = true
                }
            } catch {
                presentUnknownErrorAlert = true
            }
            
            if database.initializationError != nil {
                presentDatabaseInitializationError = true
            }
        }
        .sheet(item: $addFolderRequest) { request in
            AddFolderForm(parentFolder: request.parent)
        }
        .task {
            // Attempt to run any needed maintenance on the iris database.
            do {
                try await irisContext.runMaintenance()
            } catch {
                Log.logger.error("Failed to run maintenance on IrisDB")
            }

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
            Link(destination: URL(string: "mailto:support@tryminna.com")!) {
                Text("Email Support")
            }
        } message: {
            // TODO: Add better setup instructions.
            Text("Please enable Apple Intelligence in your device's settings to use Minna. After enabling Apple Intelligence in settings you will need to restart the application.")
        }
        .alert("An unknown error occurred while creating the Search Database", isPresented: $presentUnknownErrorAlert) {
            Link(destination: URL(string: "mailto:support@tryminna.com")!) {
                Text("Email Support")
            }
        }
        .alert("Minna's database failed to initialize.", isPresented: $presentDatabaseInitializationError) {
            Link(destination: URL(string: "mailto:support@tryminna.com")!) {
                Text("Email Support")
            }
        } message: {
            Text("Please contact support (support@tryminna.com). Error: \(database.initializationError?.localizedDescription ?? "unknown")")
        }
        .standardDropDestination(presented: $isDroppingFile, selectedFolder: navigationRouter.currentFolder, modelContext: modelContext, irisContext: irisContext, database: database)
        .sheet(isPresented: $presentingDiscordSheet) {
            AnnouncementView(announcement: Announcement(
                title: "Join our Discord!",
                caption: nil,
                description: "Get app support, send feedback, and talk about features you would love! The Discord is a great place to get involved with Minna.",
                image: ImageResource(name: "discord_announcement", bundle: .main),
                urlLabel: "Join the discord",
                urlSymbol: SFSymbol.arrowUpRight.rawValue,
                url: URL(string: "https://discord.gg/fveUWjck3W")!
            ))
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
