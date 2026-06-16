//
//  DashboardScreen.swift
//  IrisUITests
//
//  Page object for the main navigation window. Page objects keep element
//  lookups in one place so tests read as intent, not as query strings.
//

import XCTest

struct DashboardScreen {
    let app: XCUIApplication

    /// The toolbar button that adds a new folder. Anchored on the
    /// `navigation.addItem` accessibility identifier set in `NavigationCore`.
    var addItemButton: XCUIElement {
        app.buttons["navigation.addItem"]
    }

    /// The primary window of the application.
    var window: XCUIElement {
        app.windows.firstMatch
    }

    /// Waits for the main window to appear and returns whether it did.
    @discardableResult
    func waitForLoad(timeout: TimeInterval = 10) -> Bool {
        window.waitForExistence(timeout: timeout)
    }

    /// Taps the add-item toolbar button.
    func addItem() {
        addItemButton.click()
    }
}
