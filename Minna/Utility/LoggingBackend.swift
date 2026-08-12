//
//  LoggingBackend.swift
//  Minna
//
//  Created by Taylor Lineman on 8/7/26.
//

import Logging
import os
internal import SwiftSoup

struct LoggingBackend: LogHandler {
    #if DEBUG
    public var logLevel: Logging.Logger.Level = .debug
    #else
    public var logLevel: Logging.Logger.Level = .info
    #endif
    
    public var metadata: Logging.Logger.Metadata = [:]

    private var logger: os.Logger
    
    public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    public init(label: String) {
        if let dotPosition = label.lastIndex(of: ".") {
            let subsystemDotPosition = label.index(before: dotPosition)
            let categoryDotPosition = label.index(after: dotPosition)
            
            let subsystem = String(label[...subsystemDotPosition])
            let category = String(label[categoryDotPosition...])
                            
            self.init(subsystem: subsystem, category: category)
        } else {
            self.init(subsystem: label, category: "generic")
        }
    }
    
    public init(subsystem: String, category: String) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    public func log(event: LogEvent) {
        let logLine = makeLogLine(event: event)
        let level = OSLogType.from(level: event.level)
        
        logger.log(level: level, "\(logLine, privacy: .auto)")
    }
    
    private func makeLogLine(event: LogEvent) -> String {
        var logLine: String = ""
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        logLine.append("[\(timestamp)] ")
        
        let levelString = event.level.rawValue.uppercased()
        logLine.append("[\(levelString)] ")
        
        logLine.append(": \(event.message) ")
        
        // Merge handler metadata with message metadata
        let combinedMetadata = LoggingBackend.prepareMetadata(base: self.metadata, explicit: event.metadata)

        // Format metadata
        let metadataString = combinedMetadata?.compactMap { key, value in
            return "\(key): \(value)"
        }.joined(separator: ",") ?? "{ }"

        if !metadataString.isEmpty {
            logLine.append("-- { \(metadataString) } ")
        }
        
        if let error = event.error {
            logLine.append("-- \(error)")
        }

        return logLine.trim()
    }

    static func prepareMetadata(base: Logging.Logger.Metadata, explicit: Logging.Logger.Metadata?) -> Logging.Logger.Metadata? {
        guard let explicit else { return base }
        
        var metadata = base
        metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
        
        return metadata
    }
}

extension OSLogType {
    /// https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code
    nonisolated static func from(level: Logging.Logger.Level) -> Self {
        switch level {
        case .trace:
            // There is no trace in `OSLog` so use `debug`
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            // According to the documentation, `default` is `notice`.
            return .default
        case .warning:
            // There is no `warning` in `OSLog` so use `info`
            return .info
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}
