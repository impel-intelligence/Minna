//
//  ColorHexTests.swift
//  Minna
//
//  Created by Taylor Lineman on 6/16/26.
//

@testable import Minna
import SwiftUI
import Testing

struct ColorHexTests {
    @Test func sixDigitHexParsesChannels() {
        let color = NSColor(hex: "FF8800")
        #expect(abs(color.redComponent - 1.0) < 0.01)
        #expect(abs(color.greenComponent - 0.533) < 0.01)
        #expect(color.blueComponent < 0.01)
    }

    @Test func leadingHashIsIgnored() {
        #expect(NSColor(hex: "#00FF00").hexString == NSColor(hex: "00FF00").hexString)
    }

    @Test func hexStringRoundTrips() {
        let original = "#3366CC"
        #expect(NSColor(hex: original).hexString == original)
    }

    @Test func invalidHexFallsBackToBlack() {
        let color = NSColor(hex: "not-a-color")
        #expect(color.redComponent < 0.01)
        #expect(color.greenComponent < 0.01)
        #expect(color.blueComponent < 0.01)
    }
}
