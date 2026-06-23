//
//  Themes.swift
//  Iris
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
            return IrisAsset.Assets.Champagne.background.swiftUIColor
        case .lavender:
            return IrisAsset.Assets.Lavender.background.swiftUIColor
        case .azure:
            return IrisAsset.Assets.Azure.background.swiftUIColor
        case .mint:
            return IrisAsset.Assets.Mint.background.swiftUIColor
        case .rose:
            return IrisAsset.Assets.Rose.background.swiftUIColor
        }
    }

    var text: Color {
        switch self {
        case .champagne:
            return IrisAsset.Assets.Champagne.text.swiftUIColor
        case .lavender:
            return IrisAsset.Assets.Lavender.text.swiftUIColor
        case .azure:
            return IrisAsset.Assets.Azure.text.swiftUIColor
        case .mint:
            return IrisAsset.Assets.Mint.text.swiftUIColor
        case .rose:
            return IrisAsset.Assets.Rose.text.swiftUIColor
        }
    }
}
