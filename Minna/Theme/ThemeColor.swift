//
//  Themes.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

enum ThemeColor: Int, Codable, CaseIterable, CustomStringConvertible, Identifiable {
    var id: Int { rawValue }
    
    case azure
    case champagne
    case lavender
    case mint
    case rose
    
    static var random: ThemeColor {
        return ThemeColor(rawValue: Int.random(in: 0...ThemeColor.rose.rawValue))!
    }
    
    var description: String {
        switch self {
        case .champagne:
            return "Champagne"
        case .lavender:
            return "Lavender"
        case .azure:
            return "Azure"
        case .mint:
            return "Mint"
        case .rose:
            return "Rose"
        }
    }
    
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
