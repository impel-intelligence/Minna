//
//  FolderCard.swift
//  Minna
//
//  Created by Taylor Lineman on 7/10/26.
//

import SwiftUI
import SFSafeSymbols
import DatabaseSchema

struct FolderCard: View {
    @State var folder: Folder
        
    var body: some View {
        HStack {
            folder.icon.image()
            Text(folder.name)
        }
        .foregroundStyle(folder.icon.color.text)
        .font(.headline)
        .padding(.horizontal, 10)
        .frame(width: 150, height: 50, alignment: .leading)
        .background(folder.icon.color.background)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var editingTitle: Bool = false
    @Previewable @State var editingDescription: Bool = false

    FolderCard(folder: Folder(name: "Open Coursework", icon: .init(symbol: .symbol(SFSymbol.leaf.rawValue), color: .rose)))
}
