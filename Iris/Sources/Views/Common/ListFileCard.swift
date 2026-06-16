//
//  ListFileCard.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

struct ListFileCard: View {
    let file: File
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text(file.title)
                    .font(.title3)
                    .fontDesign(.serif)
                Text(file.createdAt, style: .relative)
                Spacer()
                HStack(alignment: .center) {
                    Image(file.type.icon)
                    Text(file.source)
                        .textCase(.uppercase)
                }
                .font(.system(size: 10, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(IrisAsset.Assets.pillBackground.swiftUIColor)
                .clipShape(.rect(cornerRadius: 4))
            }
            Text(file.shortDescription)
                .font(.subheadline)
                .fontDesign(.serif)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(file.color.lightBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    ListFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("text.align.left"))), title: "Hello World", shortDescription: "This is a quick description of this file and the content it contains.", color: .random, type: .webpage, url: URL(string: "https://google.com")!, bookmark: nil, source: "google.com", order: 1))
    ListFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("microphone"))), title: "Lecture 10/20/26", shortDescription: "Your teacher discussed the theory of relativity.", color: .random, type: .recording, url: URL(string: "https://google.com")!, bookmark: nil, source: "recording", order: 2))
    ListFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("sparkles"))), title: "C Mutex Questions", shortDescription: "Provided a C mutex example from class and helped debug an assignment.", color: .random, type: .askIris, url: URL(string: "https://google.com")!, bookmark: nil, source: "ask iris", order: 3))
    
}
