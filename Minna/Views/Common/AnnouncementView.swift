//
//  AnnouncementView.swift
//  Minna
//
//  Created by Taylor Lineman on 9/3/26.
//

import SwiftUI
import SFSafeSymbols

struct Announcement {
    let title: String
    let caption: String?
    let description: String
    
    let image: ImageResource

    let urlLabel: String
    let urlSymbol: String
    let url: URL
}

struct AnnouncementView: View {
    @Environment(\.dismiss) var dismiss
    let announcement: Announcement
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                Image(announcement.image)
                    .accessibilityHidden(true)
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    Text(announcement.title)
                        .font(.title)
                    if let caption = announcement.caption {
                        Text(caption)
                            .font(.caption)
                    }
                    Text(announcement.description)
                    
                    Link(destination: announcement.url) {
                        HStack {
                            Text(announcement.urlLabel)
                            Image(systemName: announcement.urlSymbol)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.trailing)
            }
            Button {
                dismiss()
            } label: {
                Image(systemSymbol: .xmark)
                    .accessibilityLabel("Dismiss announcement.")
                    .padding(5)
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
            .padding(10)

        }
        .frame(width: 500)
            
    }
}

#Preview {
//    Text("Hello")
//        .sheet(isPresented: .constant(true)) {
            AnnouncementView(announcement: Announcement(
                title: "Join our Discord!",
                caption: nil,
                description: "Get app support, send feedback, and talk about feature you would love! The discord is a great place to get involved with Minna.",
                image: ImageResource(name: "discord_announcement", bundle: .main),
                urlLabel: "Join the discord",
                urlSymbol: SFSymbol.arrowUpRight.rawValue,
                url: URL(string: "https://discord.gg/fveUWjck3W")!
            ))
//        }
}
