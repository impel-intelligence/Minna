//
//  ProviderToAssetMap.swift
//  Minna
//
//  Created by Taylor Lineman on 7/1/26.
//

import SwiftUI
import ModelManager

protocol AssetProvider {
    static var marketingName: String { get }
    static var image: ImageResource { get }
    static var background: Color { get }
}

extension AnthropicProvider: AssetProvider {
    static var marketingName: String { "Claude (Anthropic)" }
    static var image: ImageResource { .Providers.Claude.logo }
    static var background: Color { .Providers.Claude.background }
}
