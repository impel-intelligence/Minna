//
//  ThemeColor+Color.swift
//  Minna
//
//  Created by Taylor Lineman on 6/30/26.
//

import DatabaseSchema
import SwiftUI

extension ThemeColor {
    var background: Color {
        switch self {
        case .champagne:
            return Color.Champagne.background
        case .lavender:
            return Color.Lavender.background
        case .azure:
            return Color.Azure.background
        case .mint:
            return Color.Mint.background
        case .rose:
            return Color.Rose.background
        }
    }
    
    var text: Color {
        switch self {
        case .champagne:
            return Color.Champagne.text
        case .lavender:
            return Color.Lavender.text
        case .azure:
            return Color.Azure.text
        case .mint:
            return Color.Mint.text
        case .rose:
            return Color.Rose.text
        }
    }
}

