//
//  ThemeColor+Environment.swift
//  Minna
//
//  Created by Taylor Lineman on 7/7/26.
//

import SwiftUI
import DatabaseSchema

extension EnvironmentValues {
    @Entry var theme: ThemeColor = ThemeColor.azure
}

extension View {
    func theme(_ theme: ThemeColor) -> some View {
        environment(\.theme, theme)
    }
}

extension Scene {
    func theme(_ theme: ThemeColor) -> some Scene {
        environment(\.theme, theme)
    }
}
