//
//  ChatView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/29/26.
//

import SwiftUI
import MinnaChat

struct ChatView: View {
    @Environment(\.irisContext) var irisContext
    @State var chatInstance: ChatInstance?
    @State var chatMessage: String = ""
    
    var body: some View {
        ScrollView {
            if let chatInstance {
                Text(chatInstance.currentGeneration)
            }
        }
        .safeAreaInset(edge: .bottom) {
            chatBox
        }
        .task {
            do {
                chatInstance = ChatInstance(irisDB: try irisContext.database)
            } catch {
                print("Failed to get database \(error)")
            }
        }
    }
    
    var chatBox: some View {
        HStack {
            Image(.impelLogo)
                .resizable()
                .frame(width: 36, height: 36)
                .accessibilityLabel("Minna Logo")
            SearchBar(placeHolder: "Search or Ask for Anything", searchQuery: $chatMessage) {
                Task {
                    let tmpMessage = chatMessage
                    chatMessage = ""
                    do {
                        try await chatInstance?.sendMessage(tmpMessage)
                    } catch {
                        if chatMessage.isEmpty {
                            chatMessage = tmpMessage
                        }
                        print("Failed to send chat message \(error)")
                    }
                }
            }
            
        }
        .padding([.bottom], 20)
    }
}

#Preview {
    ChatView()
}

