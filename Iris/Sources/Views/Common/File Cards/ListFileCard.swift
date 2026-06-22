//
//  ListFileCard.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSafeSymbols

struct ListFileCard: View {
    @State var file: File

    @Binding var editingTitle: Bool
    @Binding var editingDescription: Bool
    
    @FocusState var focusedField: CardEditField?

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                if editingTitle {
                    TextField("Title", text: $file.title, axis: .vertical)
                        .focused($focusedField, equals: .title)
                        .font(.title3)
                        .fontDesign(.serif)
                        .foregroundStyle(file.color.text)
                        .onSubmit {
                            self.editingTitle = false
                        }
                } else {
                    Text(file.title)
                        .font(.title3)
                        .fontDesign(.serif)
                        .foregroundStyle(file.color.text)
                }
                Spacer()
                HStack(alignment: .center) {
                    Image(systemSymbol: file.type.icon)
                        .foregroundStyle(file.color.text)
                    Text(file.type.description)
                        .textCase(.uppercase)
                        .foregroundStyle(file.color.text)
                }
                .font(.system(size: 10, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(IrisAsset.Assets.pillBackground.swiftUIColor)
                .clipShape(.rect(cornerRadius: 4))
            }
            if editingDescription {
                TextField("Description", text: $file.shortDescription, axis: .vertical)
                    .focused($focusedField, equals: .description)
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .lineLimit(2)
                    .foregroundStyle(file.color.text)
                    .onSubmit {
                        self.editingDescription = false
                    }

            } else {
                Text(file.shortDescription)
                    .font(.subheadline)
                    .fontDesign(.serif)
                    .lineLimit(2)
                    .foregroundStyle(file.color.text)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(file.color.background)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var editingTitle: Bool = false
    @Previewable @State var editingDescription: Bool = false

    ListFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol(SFSymbol.textAlignleft.rawValue), color: .rose)), title: "Hello World", shortDescription: "This is a quick description of this file and the content it contains.", color: .random, type: .webpage, url: URL(string: "https://google.com")!, bookmark: nil, source: "google.com"), editingTitle: $editingTitle, editingDescription: $editingDescription)
    ListFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol(SFSymbol.microphone.rawValue), color: .lavender)), title: "Lecture 10/20/26", shortDescription: "Your teacher discussed the theory of relativity.", color: .random, type: .recording, url: URL(string: "https://google.com")!, bookmark: nil, source: "recording"), editingTitle: $editingTitle, editingDescription: $editingDescription)
    ListFileCard(file: File(createdAt: .now, folder: Folder(name: "", icon: .init(symbol: .symbol(SFSymbol.sparkles.rawValue), color: .champagne)), title: "C Mutex Questions", shortDescription: "Provided a C mutex example from class and helped debug an assignment.", color: .random, type: .askIris, url: URL(string: "https://google.com")!, bookmark: nil, source: "ask iris"), editingTitle: $editingTitle, editingDescription: $editingDescription)
    
}
