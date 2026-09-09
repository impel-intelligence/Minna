//
//  NoteTakerControlButtonStyle.swift
//  Minna
//
//  Created by Taylor Lineman on 9/9/26.
//

import SwiftUI

struct CenteredLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

struct NoteTakerControlSimpleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            .contentShape(.rect)
            .labelStyle(CenteredLabelStyle())
    }
}

struct NoteTakerControlButtonStyle: ButtonStyle {
    @Binding var isActive: Bool
    var activeColor: Color
    var activeTextColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isActive ? activeTextColor : .primary)
            .padding(10)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .glassEffect(
                .regular.tint(isActive ? activeColor.opacity(0.75) : nil).interactive(),
                in: .rect(cornerRadius: 12)
            )
            .contentShape(.rect)
            .labelStyle(CenteredLabelStyle())
    }
}


#Preview {
    @Previewable @State var isActive: Bool = false
    
    Button {
        isActive.toggle()
    } label: {
        Text("Three")
    }
    .buttonStyle(NoteTakerControlButtonStyle(isActive: $isActive, activeColor: .red, activeTextColor: .white))
    
    Button {
        isActive.toggle()
    } label: {
        Text("Three")
    }
    .buttonStyle(NoteTakerControlSimpleButtonStyle())

}
