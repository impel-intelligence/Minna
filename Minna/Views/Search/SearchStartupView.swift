//
//  SearchStartupView.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//  Reworked into the Ask Minna compose wrapper by Claude Opus 4.8 (Anthropic) on 2026-07-08.
//

import SwiftUI
import SFSafeSymbols
import SwiftData
import SentrySwift
import DatabaseSchema

/// The Search tab's entry point. It owns an in-memory *draft* chat (created with
/// `Chat.make`, not yet persisted) and hosts ``AskMinnaView`` in its compose
/// state. Persisting the draft happens inside `AskMinnaView` on the first
/// message; the New Chat toolbar button swaps in a fresh draft, which — via the
/// changing `.id` — resets `AskMinnaView` to compose.
///
/// - Authored by: Claude Opus 4.8 (Anthropic)
struct SearchStartupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.database) private var database

    @State private var draft: Chat?

    var body: some View {
        Group {
            if let draft {
                AskMinnaView(chat: draft, viewMode: .startup, newChat: startNewChat)
                    .id(draft.uuid)
            } else {
                ContentUnavailableView("Couldn't start a chat", systemSymbol: .exclamationmarkTriangle)
            }
        }
        .onAppear {
            if draft == nil {
                draft = Chat.make(in: database.unfiledFolder())
            }
        }
    }

    private func startNewChat() {
        draft = Chat.make(in: database.unfiledFolder())
    }
}

extension SearchStartupView: Navigable {
    static var label: Label<Text, ModifiedContent<Image, AccessibilityAttachmentModifier>> {
        Label {
            Text("Search")
        } icon: {
            Image(systemSymbol: .magnifyingglass)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    SearchStartupView()
        .navigationTitle("Ask Minna")
        .modelContainer(SampleDatabase.shared.modelContainer)
        .database(SampleDatabase.shared)
        .irisContext(IrisContext(modelContainer: SampleDatabase.shared.modelContainer))
}
