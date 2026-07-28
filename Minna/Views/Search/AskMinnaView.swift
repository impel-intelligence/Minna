//
//  ChatView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//  Edited by Claude Sonnet 4.6 (Anthropic) on 2026-07-28

import SwiftUI
import MinnaChat
import SwiftData
import DatabaseSchema
import Textual
import SFSafeSymbols
import ModelManager
import ModernSettingsWindow
import OrderedCollections
import AnyLanguageModel
import Logging

struct AskMinnaView: View {
    enum ViewMode {
        case startup
        case chat
        case searching
    }
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.router) var navigationRouter
    @Environment(\.openWindow) var openWindow
        
    @Namespace private var searchContainerTransitions

    @State private var presentModelPicker: Bool = false
    
    @State private var citationHandler: CitationHandler = CitationHandler()
    
    @State var chatter: Chatter
    @State var viewMode: ViewMode
    
    @State var searchRouter: RouterCore?
    
    @State var searchTask: Task<Void, Never>?

    @State var searchResults: [File] = []

    /// Invoked by the New Chat toolbar button. `nil` hides the button (e.g. when viewing an existing chat pushed from a folder).
    var newChat: (() -> Void)?
    
    init(chat: Chat, viewMode: ViewMode, newChat: (() -> Void)? = nil) {
        self._chatter = State(initialValue: Chatter(chat: chat, instructions: AskMinnaInstructions(), availableTools: AvailableTool.allCases))
        self.viewMode = viewMode
        self.newChat = newChat
    }

    var body: some View {
        GeometryReader { reader in
            ScrollView {
                switch viewMode {
                case .startup:
                    startup()
                        .frame(width: reader.size.width, height: reader.size.height)
                case .searching:
                    searching()
                case .chat:
                    TranscriptView(chatter: chatter, limitSize: true, reader: reader)
                }
            }
        }
        .environment(citationHandler)
        .theme(chatter.chat.theme)
        .navigationTitle(chatter.chat.title())
        .defaultScrollAnchor(viewMode == .chat ? .bottom : .top)
        .scrollDisabled(viewMode == .startup)
        .safeAreaInset(edge: .bottom) {
            searchCluster
        }
        .inspector(isPresented: $citationHandler.citationSidebarOpen) {
            CitationColumnView(citations: $citationHandler.citations)
        }
        .environment(\.openURL, OpenURLAction { url in
            do {
                try URLHandler.handle(url, context: modelContext, router: navigationRouter, openWindow: openWindow)
                return .handled
            } catch {
                Log.logger.error("Failed to handle url", error: error, metadata: ["url": "\(url)"])
                return .systemAction
            }
        })
        .task {
            do {
                try await chatter.gatherProviders(modelContext: modelContext, irisContext: irisContext)
            } catch {
                Log.logger.error("Failed to gather providers", error: error)
            }
        }
        .onAppear {
            do {
                searchRouter = try RouterCore()
            } catch {
                Log.logger.error("Failed to create search router", error: error)
            }
        }
        .toolbar {
            if let newChat {
                ToolbarItem(id: "newChat") {
                    Button {
                        newChat()
                    } label: {
                        Label("New Chat", systemSymbol: .squareAndPencil)
                    }
                }
            }
            ToolbarItem(id: "sidebar") {
                Button {
                    citationHandler.citationSidebarOpen.toggle()
                } label: {
                    Label("Toggle Sidebar", systemSymbol: .sidebarRight)
                }
            }
        }
        .onChange(of: chatter.chatMessage) { _, newValue in
            searchTask?.cancel()

            searchTask = Task {
                // Debounce: wait 20ms before searching
                try? await Task.sleep(for: Duration.milliseconds(50))
                
                // Check if cancelled during wait
                guard !Task.isCancelled else { return }
                
                do {
                    try await searchIris(query: newValue)
                } catch is CancellationError {
                    
                } catch {
                    print("Failed to search iris \(newValue) \(error)")
                }
            }
        }

    }
    
    @ViewBuilder
    private func searching() -> some View {
        VStack {
            ForEach(searchResults) { file in
                ListFileCard(file: file, editingTitle: .constant(false), editingDescription: .constant(false))
                    .id(file)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .scrollTargetLayout()
        .transition(.move(edge: .bottom).combined(with: .opacity))
//        .safeAreaInset(edge: .bottom) {
//            if viewMode == .searching {
//                searchCluster
//            }
//        }
    }
    
    @ViewBuilder
    private func startup() -> some View {
        VStack(spacing: 5) {
            Image("impel_logo")
                .resizable()
                .frame(width: 45, height: 45)
                .accessibilityLabel("Minna Logo")
            Text("Hey \(NSUserFirstName())!")
                .font(.system(size: 36, design: .serif))
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var searchCluster: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                presentModelPicker.toggle()
            } label: {
                if let selectedModel = chatter.selectedModel {
                    ModelName(model: selectedModel)
                } else {
                    Text("No Model Selected")
                }
            }
            .popover(isPresented: $presentModelPicker) {
                ModelSelector(providerDatabase: $chatter.providerDatabase, selectedModel: $chatter.selectedModel, selectedProvider: $chatter.selectedProvider)
            }
            .buttonStyle(.glass)
            IndexingSearchBar(placeHolder: "Search or Ask for Anything", searchQuery: $chatter.chatMessage) {
                submit()
            }
            .disabled(chatter.selectedModel == nil || chatter.chatInstance == nil)
        }
        .frame(maxWidth: 640)
        .padding(.bottom, 20)
        .id("search")
        .matchedGeometryEffect(id: "search", in: searchContainerTransitions)
    }

    private func submit() {
        if viewMode == .startup || viewMode == .searching {
            modelContext.insert(chatter.chat.file)
            viewMode = .chat // Start animations
        }
        
        Task {
            do {
                try await chatter.submit()
            } catch {
                Log.logger.error("Failed to submit chat message", error: error)
            }
        }
    }
    
    private func searchIris(query: String) async throws {
        // Only allow searching during the startup or searching mode
        guard viewMode == .startup || viewMode == .searching else { return }
        
        let fileUUIDs = try await irisContext.search(query: query)
        
        let descriptor = FetchDescriptor<File>(predicate: #Predicate { fileUUIDs.contains($0.uuid) })
        let unsorted = try modelContext.fetch(descriptor)
        
        let searchRanking = fileUUIDs.enumerated().reduce(into: [:]) { partialResult, element in
            partialResult[element.element] = element.offset
        }
        var orderedByRank = [File?](repeating: nil, count: fileUUIDs.count)
        
        // O(n) loop over the retrieved documents, placing each document into the array at its rank position.
        for file in unsorted {
            if let rank = searchRanking[file.uuid] {
                orderedByRank[rank] = file
            }
        }
        
        searchResults = orderedByRank.compactMap { $0 }
        
        if !searchResults.isEmpty {
            viewMode = .searching
        }
    }

}

#Preview {
    AskMinnaView(chat: Chat.make(in: SampleDatabase.shared.sampleFolders.first!), viewMode: .chat) {
        
    }
    .irisContext(IrisContext(modelContainer: SampleDatabase.shared.modelContainer))
    .modelContext(SampleDatabase.shared.context)
}
