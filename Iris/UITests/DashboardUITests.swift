//
//  DashboardUITests.swift
//  IrisUITests
//
//  Example UI tests exercising the main navigation window. UI automation on
//  macOS uses XCUITest (XCTest), which runs the app as a separate process —
//  Swift Testing's `@Test` macros cannot drive the UI runner, so these stay
//  in XCTest while logic tests live in the Swift Testing `IrisTests` target.
//

import XCTest

final class DashboardUITests: IrisUITestCase {
    func testAppLaunchesAndShowsMainWindow() {
        let app = launchApp()
        let screen = DashboardScreen(app: app)

        XCTAssertTrue(screen.waitForLoad(), "Main window should appear after launch")
    }

    func testAddItemButtonIsPresent() {
        let app = launchApp()
        let screen = DashboardScreen(app: app)
        screen.waitForLoad()

        XCTAssertTrue(
            screen.addItemButton.waitForExistence(timeout: 5),
            "The add-item toolbar button should be reachable via its accessibility identifier"
        )
    }
}
