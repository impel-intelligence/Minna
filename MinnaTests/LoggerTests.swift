//
//  LoggerTests.swift
//  Minna
//
//  Created by Taylor Lineman on 8/7/26.
//


@testable import Minna
import SwiftUI
import Testing

struct LoggerTests {
    /// Tests to make sure the logger uses value type semantics
    /// https://swiftpackageindex.com/apple/swift-log/main/documentation/logging/implementingaloghandler#Implement-with-value-type-semantics
    @Test
    func logHandlerValueSemantics() {
        LoggingSystem.bootstrap(MyLogHandler.init)
        var logger1 = Logger(label: "first logger")
        logger1.logLevel = .debug
        logger1[metadataKey: "only-on"] = "first"
        
        
        var logger2 = logger1
        logger2.logLevel = .error                  // Must not affect logger1
        logger2[metadataKey: "only-on"] = "second" // Must not affect logger1
        
        
        // These expectations must pass
        #expect(logger1.logLevel == .debug)
        #expect(logger2.logLevel == .error)
        #expect(logger1[metadataKey: "only-on"] == "first")
        #expect(logger2[metadataKey: "only-on"] == "second")
    }
}
