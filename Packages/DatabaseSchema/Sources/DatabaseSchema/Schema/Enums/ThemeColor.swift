//
//  Themes.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

public enum ThemeColor: Int, Codable, CaseIterable, CustomStringConvertible, Identifiable {
    public var id: Int { rawValue }
    
    case azure
    case champagne
    case lavender
    case mint
    case rose
    
    public static var random: ThemeColor {
        return ThemeColor(rawValue: Int.random(in: 0...ThemeColor.rose.rawValue))!
    }
    
    public var description: String {
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
}
