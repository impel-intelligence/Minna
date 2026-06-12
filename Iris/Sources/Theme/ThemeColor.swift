//
//  Themes.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

enum ThemeColor: Int, Codable {
    case apricot
    case berry
    case blueberry
    case melon
    case grape
    
    static var random: ThemeColor {
        return ThemeColor(rawValue: Int.random(in: 0..<ThemeColor.grape.rawValue))!
    }
    
    var lightBackground: Color {
        switch self {
        case .apricot:
            return IrisAsset.Assets.Apricot.lightBackground.swiftUIColor
        case .berry:
            return IrisAsset.Assets.Berry.lightBackground.swiftUIColor
        case .blueberry:
            return IrisAsset.Assets.Blueberry.lightBackground.swiftUIColor
        case .melon:
            return IrisAsset.Assets.Melon.lightBackground.swiftUIColor
        case .grape:
            return IrisAsset.Assets.Grape.lightBackground.swiftUIColor
        }
    }
    
    var background: Color {
        switch self {
        case .apricot:
            return IrisAsset.Assets.Apricot.background.swiftUIColor
        case .berry:
            return IrisAsset.Assets.Berry.background.swiftUIColor
        case .blueberry:
            return IrisAsset.Assets.Blueberry.background.swiftUIColor
        case .melon:
            return IrisAsset.Assets.Melon.background.swiftUIColor
        case .grape:
            return IrisAsset.Assets.Grape.background.swiftUIColor
        }
    }
    
    var text: Color {
        switch self {
        case .apricot:
            return IrisAsset.Assets.Apricot.text.swiftUIColor
        case .berry:
            return IrisAsset.Assets.Berry.text.swiftUIColor
        case .blueberry:
            return IrisAsset.Assets.Blueberry.text.swiftUIColor
        case .melon:
            return IrisAsset.Assets.Melon.text.swiftUIColor
        case .grape:
            return IrisAsset.Assets.Grape.text.swiftUIColor
        }
    }
}
