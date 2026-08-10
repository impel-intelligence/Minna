//
//  FeatureOverview.swift
//  Minna
//
//  Created by Taylor Lineman on 8/10/26.
//

import SwiftUI
import SFSafeSymbols

struct OnboardingPage: Identifiable, Equatable, Hashable {
    let id: UUID = UUID()
    let text: String
    let video: String
}

struct FeatureOverview: View {
    static let pages: [OnboardingPage] = [
        OnboardingPage(text: "Search using natural language or keywords.", video: "search"),
        OnboardingPage(text: "Add PDFs, and text files.", video: "pdfs_text"),
        OnboardingPage(text: "Responses come directly from your database.", video: "knowledge_database"),
        OnboardingPage(text: "Ask questions across your entire database.", video: "ask"),
        OnboardingPage(text: "Chat with a single document.", video: "chat")
    ]

    let done: () -> Void
    @State var currentPage: OnboardingPage? = FeatureOverview.pages.first

    var body: some View {
        GeometryReader { reader in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(FeatureOverview.pages) { page in
                        HStack {
                            OnboardingCard(page: page) {
                                done()
                            } next: {
                                withAnimation {
                                    if let currentPage, let currentPageIndex = FeatureOverview.pages.firstIndex(of: currentPage) {
                                        let nextIndex = FeatureOverview.pages.index(after: currentPageIndex)
                                        if nextIndex < FeatureOverview.pages.count {
                                            self.currentPage = FeatureOverview.pages[nextIndex]
                                        } else {
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                        .id(page)
                        .frame(width: reader.size.width)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentPage)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    ForEach(FeatureOverview.pages, id: \.self) { page in
                        Circle()
                            .frame(
                                width: page == currentPage ? 8 : 5,
                                height: page == currentPage ? 8 : 5
                            )
                            .foregroundStyle(Color.accentColor)
                            .opacity(page == currentPage ? 1 : 0.5)
                            .contentShape(.rect)
                            .onTapGesture {
                                withAnimation {
                                    currentPage = page
                                }
                            }
                            .accessibilityAddTraits(.isButton)

                    }
                }
                .padding(.vertical, 34)
            }
            .animation(.default, value: currentPage)
            .frame(width: reader.size.width, height: reader.size.height)
        }
    }
}

struct OnboardingCard: View {
    let page: OnboardingPage
    let contentURL: URL?
    let skip: () -> Void
    let next: () -> Void

    init(page: OnboardingPage, skip: @escaping () -> Void, next: @escaping () -> Void) {
        self.page = page
        self.skip = skip
        self.next = next
        self.contentURL = Bundle.main.url(forResource: page.video, withExtension: "mp4")
    }

    var body: some View {
        VStack() {
            if let contentURL {
                LoopingVideoPlayer(url: contentURL)
                    .frame(width: 290, height: 150)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            } else {
                ContentUnavailableView("No Video", systemSymbol: .videoSlash)
                    .frame(width: 290, height: 150)
            }
            Spacer()
            Text(page.text)
                .font(.title2)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()

            HStack {
                Button("Skip") {
                    skip()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Spacer()
                Button {
                     next()
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemSymbol: .arrowForward)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(Color.accentColor)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .contentShape(.rect)
            }
            .padding(25)
        }
        .frame(width: 290, height: 290)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    FeatureOverview {
        
    }
    .frame(width: 700, height: 450)
    .toolbar(removing: .title)
    .toolbarBackground(.hidden, for: .windowToolbar)
    .toolbar {
        ToolbarItem(placement: .principal) {
            MinnaLogo()
            
        }
        .sharedBackgroundVisibility(.hidden)
    }
}
