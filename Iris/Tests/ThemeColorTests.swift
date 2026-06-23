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
    @Test(arguments: ThemeColor.allCases)
    func codableRoundTrips(_ theme: ThemeColor) throws {
        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(ThemeColor.self, from: data)
        #expect(decoded == theme)
    }

    @Test func rawValuesAreStable() {
        #expect(ThemeColor.azure.rawValue == 0)
        #expect(ThemeColor.rose.rawValue == 4)
    }
}
