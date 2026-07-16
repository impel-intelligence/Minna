//
//  ChatView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

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

struct AskMinnaView: View {
    enum ViewMode {
        case startup
        case chat
    }
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.router) var navigationRouter

    @Namespace private var searchContainerTransitions

    @State private var presentModelPicker: Bool = false
    
    @State private var citationHandler: CitationHandler = CitationHandler()
    
    @State var chatter: Chatter
    @State var viewMode: ViewMode

    /// Invoked by the New Chat toolbar button. `nil` hides the button (e.g. when viewing an existing chat pushed from a folder).
    var newChat: (() -> Void)?
    
    init(chat: Chat, viewMode: ViewMode, newChat: (() -> Void)? = nil) {
        self._chatter = State(initialValue: Chatter(chat: chat))
        self.viewMode = viewMode
        self.newChat = newChat
    }

    var body: some View {
        Group {
            switch viewMode {
            case .startup:
                startup()
            case .chat:
                TranscriptView(chatter: chatter, limitSize: true)
                    .safeAreaInset(edge: .bottom) {
                        if viewMode == .chat {
                            searchCluster
                        }
                    }
                    .environment(citationHandler)
                    .inspector(isPresented: $citationHandler.citationSidebarOpen) {
                        CitationColumnView(citations: $citationHandler.citations)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .theme(chatter.chat.theme)
        .navigationTitle(chatter.chat.title())
        .task {
            do {
                try await chatter.gatherProviders(modelContext: modelContext, irisContext: irisContext)
            } catch {
                print("Failed to gather providers \(error)")
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
    }

    
    // MARK: Startup State
    private func startup() -> some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 5) {
                Image("impel_logo")
                    .resizable()
                    .frame(width: 45, height: 45)
                    .accessibilityLabel("Minna Logo")
                Text("Hey \(NSUserFirstName())!")
                    .font(.system(size: 36, design: .serif))
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            searchCluster
            Spacer()
        }
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
        .padding(.bottom, viewMode == .chat ? 20 : 0)
        .id("search")
        .matchedGeometryEffect(id: "search", in: searchContainerTransitions)
    }

    private func submit() {
        if viewMode == .startup {
            modelContext.insert(chatter.chat.file)
            viewMode = .chat // Start animations
        }

        Task {
            try await chatter.submit()
        }
    }
}

#Preview {
    @Previewable var controller = IrisDBController(modelContainer: SampleDatabase.shared.modelContainer)
    
    AskMinnaView(chat: Chat.make(in: SampleDatabase.shared.sampleFolders.first!), viewMode: .chat) {
        
    }
    .irisContext(controller.mainContext)
    .modelContext(SampleDatabase.shared.context)
}
