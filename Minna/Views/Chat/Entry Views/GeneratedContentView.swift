//
//  GeneratedContentView.swift
//  Minna
//
//  Created by Taylor Lineman on 7/2/26.
//

import SwiftUI
import AnyLanguageModel

struct GeneratedContentView: View {
    let content: GeneratedContent
    let level: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            switch content.kind {
            case .string(let string):
                Text(string)
            case .array(let array):
                ForEach(array, id: \.jsonString) { subContent in
                    GeneratedContentView(content: subContent, level: level + 1)
                }
            case .number(let number):
                Text("\(number)")
            case .bool(let bool):
                Text(bool.description)
            case .null:
                Text("null")
            default:
                // TODO: Pretty Print JSON
                Text(content.jsonString)
                    .textSelection(.enabled)
            }
        }
        .padding(.leading, CGFloat(level * 10))
    }
}
