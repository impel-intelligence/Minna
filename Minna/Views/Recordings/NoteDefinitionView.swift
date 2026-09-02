//
//  NoteDefinitionView 2.swift
//  Minna
//
//  Created by Taylor Lineman on 9/2/26.
//

import SwiftUI

struct NoteDefinitionView: View {
    let cornerRadius: CGFloat = 12
    let defintion: NoteBlock.Definition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(defintion.concept)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(defintion.description)
        }
        .padding(10)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 300)
        .background(.background)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 5)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
        }
    }
}
