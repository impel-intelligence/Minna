//
//  FileChat.swift
//  Minna
//
//  Created by Taylor Lineman on 7/16/26.
//

import SwiftUI
import MinnaChat
import SwiftData
import DatabaseSchema

struct FileChat: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.irisContext) var irisContext
    @Environment(\.router) var navigationRouter

    @State private var presentModelPicker: Bool = false
    
    @State private var citationHandler: CitationHandler = CitationHandler()
    
    @State var chatter: Chatter
    let file: File

    init(file: File) {
        self.file = file
        let chat = Chat.make(on: file)
        self._chatter = State(initialValue: Chatter(chat: chat))
    }
    
    var body: some View {
        TranscriptView(chatter: chatter, limitSize: false)
            .safeAreaInset(edge: .bottom) {
                chatBox
            }
            .environment(citationHandler)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .theme(chatter.chat.theme)
        .task {
            modelContext.insert(chatter.chat)
            
            do {
                try await chatter.gatherProviders(modelContext: modelContext, irisContext: irisContext)
            } catch {
                print("Failed to gather providers: \(error)")
            }
        }
    }
    
    var chatBox: some View {
        VStack(alignment: .leading) {
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
            SearchBar(placeHolder: "Ask anything about \(file.title)", searchQuery: $chatter.chatMessage) {
                Task {
                    do {
                        try await chatter.submit()
                    } catch {
                        print("Failed to send chat: \(error)")
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}

//#Preview {
//    @Previewable var controller = IrisDBController(modelContainer: SampleDatabase.shared.modelContainer)
//    
//    AskMinnaView(chat: Chat.make(in: SampleDatabase.shared.sampleFolders.first!), viewMode: .chat) {
//        
//    }
//    .irisContext(controller.mainContext)
//    .modelContext(SampleDatabase.shared.context)
//}
