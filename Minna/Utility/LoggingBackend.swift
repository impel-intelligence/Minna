//
//  LoggingBackend.swift
//  Minna
//
//  Created by Taylor Lineman on 8/7/26.
//

import Logging
import os

struct LoggingBackend: LogHandler {
    var logLevel: Logging.Logger.Level = .debug
    var metadata: Logging.Logger.Metadata = [:]

    var logger: os.Logger
    
    subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    init(label: String) {
        if let dotPosition = label.lastIndex(of: ".") {
            let subsystem = String(label[...dotPosition])
            let category = String(label[dotPosition...])
            
            print("GOT \(subsystem), \(category)")
    
            self.init(subsystem: subsystem, category: category)
        } else {
            self.init(subsystem: label, category: "generic")
        }
    }
    
    init(subsystem: String, category: String) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    func log(event: LogEvent) {        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let levelString = event.level.rawValue.uppercased()

        // Merge handler metadata with message metadata
        let combinedMetadata = LoggerBackend.prepareMetadata(base: self.metadata, explicit: event.metadata)

        // Format metadata
        let metadataString = combinedMetadata?.compactMap { key, value in
            return "\(key): \(value)"
        }.joined(separator: ",") ?? "{ }"


        // Create log line and print to console
        let logLine = "[\(timestamp)] [\(levelString)] [\(metadataString)]: \(event.message)"
        let level = OSLogType.from(level: event.level)
        
        logger.log(level: level, "\(logLine, privacy: .auto)")
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
