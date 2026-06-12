//
//  Folder+Label.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

extension Folder {
    @ViewBuilder
    func label() -> some View {
        Label {
            Text(name)
        } icon: {
            switch icon.symbol {
            case .emoji(let emoji):
                Text(emoji)
            case .symbol(let symbol):
                Image(systemName: symbol)
                    .accessibilityLabel(symbol)
            }
        }
    }
}
