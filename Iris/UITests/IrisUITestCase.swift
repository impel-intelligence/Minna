//
//  IrisUITestCase.swift
//  IrisUITests
//
//  Base class for UI tests. Provides a launched application and the
//  standard failure-on-interruption behavior.
//

import XCTest

class IrisUITestCase: XCTestCase {
    /// The application under test, available after `launchApp()`.
    private(set) var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Launches a fresh instance of the app and waits for it to become active.
    @discardableResult
    func launchApp() -> XCUIApplication {
        let application = XCUIApplication()
        application.launch()
        app = application
        return application
    }
}
