//
//  ThemeColorTests.swift
//  Iris
//
//  Created by Taylor Lineman on 6/16/26.
//

@testable import Iris
import SwiftUI
import Testing

struct ThemeColorTests {
    @Test(arguments: [ThemeColor.apricot, .berry, .blueberry, .melon, .grape])
    func codableRoundTrips(_ theme: ThemeColor) throws {
        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(ThemeColor.self, from: data)
        #expect(decoded == theme)
    }

    @Test func rawValuesAreStable() {
        #expect(ThemeColor.apricot.rawValue == 0)
        #expect(ThemeColor.grape.rawValue == 4)
    }
}
