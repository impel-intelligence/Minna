//
//  GridFileCard.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSafeSymbols

struct GridFileCard: View {
    @State var file: File

    @Binding var editingTitle: Bool
    @Binding var editingDescription: Bool

    @FocusState var focusedField: CardEditField?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Image(systemSymbol: file.type.icon)
                    .foregroundStyle(file.color.text)
                Text(file.type.description)
                    .textCase(.uppercase)
                    .foregroundStyle(file.color.text)
                Spacer()
            }
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundStyle(.secondary)
            if editingTitle {
                TextField("Title", text: $file.title, axis: .vertical)
                    .focused($focusedField, equals: .title)
                    .font(.title3)
                    .fontDesign(.serif)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(file.color.text)
                    .onSubmit {
                        self.editingTitle = false
                    }
            } else {
                Text(file.title)
                    .font(.title3)
                    .fontDesign(.serif)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(file.color.text)
            }
            if editingDescription {
                TextField("Description", text: $file.shortDescription, axis: .vertical)
                    .focused($focusedField, equals: .description)
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .foregroundStyle(file.color.text)
                    .onSubmit {
                        self.editingDescription = false
                    }
            } else {
                Text(file.shortDescription)
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .foregroundStyle(file.color.text)
            }
        }
        .padding(12)
        .frame(width: 150, height: 170, alignment: .top)
        .background(file.color.background)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var editingTitle: Bool = false
    @Previewable @State var editingDescription: Bool = false
    
    GridFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol(SFSymbol.textAlignleft.rawValue), color: .rose)), title: "This-is-a-long-name-with-no-spaces", shortDescription: "This is a quick description of this file and the content it contains. This is a quick description of this file and the content it contains. This is a quick description of this file and the content it contains.", color: .random, type: .webpage, url: URL(string: "https://google.com")!, bookmark: nil, source: "google.com"), editingTitle: $editingTitle, editingDescription: $editingDescription)
//    GridFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("microphone"))), title: "Lecture 10/20/26", shortDescription: "Your teacher discussed the theory of relativity. Your teacher discussed the theory of relativity. Your teacher discussed the theory of relativity.", color: .random, type: .recording, url: URL(string: "https://google.com")!, bookmark: nil, source: "recording"), editingTitle: $editingTitle, editingDescription: $editingDescription)
//    GridFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol("sparkles"))), title: "C Mutex Questions", shortDescription: "Provided a C mutex example from class and helped debug an assignment. Provided a C mutex example from class and helped debug an assignment. Provided a C mutex example from class and helped debug an assignment.", color: .random, type: .askMinna, url: URL(string: "https://google.com")!, bookmark: nil, source: "ask minna"), editingTitle: $editingTitle, editingDescription: $editingDescription)

}
