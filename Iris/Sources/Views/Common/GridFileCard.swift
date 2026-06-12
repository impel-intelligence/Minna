//
//  FileCard.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

struct GridFileCard: View {
    let file: File
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Image(file.type.icon)
                Text(file.source)
                    .textCase(.uppercase)
                Spacer()
            }
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundStyle(.secondary)
            Text(file.title)
                .font(.title3)
                .fontDesign(.serif)
            Text(file.shortDescription)
                .font(.subheadline)
                .fontDesign(.serif)

            Spacer()
        }
        .padding(12)
        .frame(width: 150, height: 170)
        .background(file.color.lightBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    GridFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("text.align.left"))), title: "Hello World", shortDescription: "This is a quick description of this file and the content it contains.", color: .random, type: .externalURL, url: URL(string: "https://google.com")!, bookmark: nil, source: "google.com", order: 1))
    GridFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("microphone"))), title: "Lecture 10/20/26", shortDescription: "Your teacher discussed the theory of relativity.", color: .random, type: .recording, url: URL(string: "https://google.com")!, bookmark: nil, source: "recording", order: 2))
    GridFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("sparkles"))), title: "C Mutex Questions", shortDescription: "Provided a C mutex example from class and helped debug an assignment.", color: .random, type: .askIris, url: URL(string: "https://google.com")!, bookmark: nil, source: "ask iris", order: 3))


}
