//
//  Folder+Label.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI
import SFSafeSymbols

extension Folder {
    @ViewBuilder
    func label() -> some View {
        Label {
            Text(name)
        } icon: {
            icon.image()
        }
    }
}

extension FolderIcon {
    enum IconSize {
        case regular
        case large
    }
    
    @ViewBuilder
    func image(size: IconSize = .regular) -> some View {
        switch self.symbol {
        case .emoji(let emoji):
            Text(emoji)
                .font(size == .large ? .system(size: 40) : nil)
        case .symbol(let name):
            let symbol = SFSymbol(rawValue: name)
            
            if size == .large {
                Image(systemSymbol: symbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 45)
            } else {
                Image(systemSymbol: symbol)
            }
        }
    }
}

#Preview {
    FolderIcon(symbol: .emoji("🥂"), color: .random).image(size: .regular)
        .border(.red)
    FolderIcon(symbol: .symbol(SFSymbol.star.rawValue), color: .random).image(size: .regular)
        .border(.red)
    Divider()
    FolderIcon(symbol: .emoji("🥂"), color: .random).image(size: .large)
        .border(.red)
    FolderIcon(symbol: .symbol(SFSymbol.star.rawValue), color: .random).image(size: .large)
        .border(.red)
}
