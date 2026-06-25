//
//  MultiPicker.swift
//  Minna
//
//  Created by Taylor Lineman on 6/15/26.
//

import SwiftUI

struct MultiPicker<Content: View, Element: Hashable>: View {
    var content: Content
    @Binding var selection: Set<Element>
    
    init(selection: Binding<Set<Element>>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._selection = selection
    }
    
    var body: some View {
        ForEach(subviews: content) { subview in
            if let tag = subview.containerValues.tag(for: Element.self) {
                // Use a toggle so we can use the default macOS checkmark gutter built into the menu view.is 
                Toggle(isOn: Binding(
                    get: { getState(for: tag) },
                    set: { setState(for: tag, isOn: $0)}
                )) {
                    subview
                }
            } else {
                subview
                    .disabled(true)
            }
        }
    }
    
    func getState(for tag: Element) -> Bool {
        return selection.contains(tag)
    }
    
    func setState(for tag: Element, isOn: Bool) {
        if isOn {
            selection.insert(tag)
        } else {
            selection.remove(tag)
        }
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["hello"]
    @Previewable @State var int: Int = 0

    Text(selection.joined(separator: " "))
        .frame(width: 100)
    
    Menu {
        Picker("Hello", selection: $int) {
            Text("Hello")
                .tag(0)
        }
        .pickerStyle(.inline)
        Divider()
        MultiPicker(selection: $selection) {
            Text("Hello")
                .tag("hello")
            Text("Hi")
                .tag("hi")
        }
    } label: {
        
    }

}
