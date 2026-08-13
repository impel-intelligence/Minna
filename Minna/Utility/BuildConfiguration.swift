//
//  BuildConfiguration.swift
//  Minna
//
//  Created by Claude Opus 5 (Anthropic) on 8/13/26.
//

import Foundation

/// Build-time configuration supplied by `Config.xcconfig`.
///
/// Values are injected into the app's `Info.plist` at build time and read back here. Every value is optional, and a missing or blank value — the default for any build made from a clean checkout — leaves the corresponding feature switched off. A build from source therefore reports no telemetry anywhere unless a developer deliberately opts in via `Config.local.xcconfig`.
///
/// - Note: `xcconfig` files treat `//` as the start of a comment, so URL-shaped values are stored without their scheme and reassembled here.
/// - Authored by: Claude Opus 5 (Anthropic)
enum BuildConfiguration {
    /// The Sentry DSN, or `nil` when crash reporting should stay disabled.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static var sentryDSN: String? {
        value(for: "SENTRY_DSN").map { "https://\($0)" }
    }

    /// The PostHog project token, or `nil` when analytics should stay disabled.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static var postHogProjectToken: String? {
        value(for: "POSTHOG_PROJECT_TOKEN")
    }

    /// The PostHog host, or `nil` when analytics should stay disabled.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static var postHogHost: String? {
        value(for: "POSTHOG_HOST").map { "https://\($0)" }
    }

    /// Whether product analytics are configured for this build.
    /// - Authored by: Claude Opus 5 (Anthropic)
    static var isAnalyticsEnabled: Bool {
        postHogProjectToken != nil && postHogHost != nil
    }

    /// Reads a string from `Info.plist`, treating unconfigured values as absent.
    ///
    /// An xcconfig variable that was never assigned survives `Info.plist` substitution as either an empty string or the literal `$(NAME)` placeholder, so both forms are reported as "not configured".
    ///
    /// - Parameter key: The `Info.plist` key to read.
    /// - Returns: The trimmed value, or `nil` when it is unset.
    /// - Authored by: Claude Opus 5 (Anthropic)
    private static func value(for key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
            return nil
        }

        return trimmed
    }
}
