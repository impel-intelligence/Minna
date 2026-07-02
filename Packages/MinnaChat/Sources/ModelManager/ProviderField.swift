//
//  ProviderField.swift
//  MinnaChat
//
//  Created by Claude Opus 4.8 (Anthropic) on 2026-07-01.
//

import Foundation

/// Describes a single user-configurable field that a ``ModelProvider`` needs in
/// order to be constructed (for example an API key or a custom base URL).
///
/// Providers expose an array of these so a settings form can be rendered
/// dynamically, without the UI knowing anything about a specific provider's
/// requirements. The `key` is used to look the value back up when constructing
/// the provider.
///
/// - Authored by: Claude Opus 4.8 (Anthropic)
public struct ProviderField: Identifiable, Hashable, Sendable {
    /// The kind of control the UI should present for a field.
    public enum Kind: Sendable {
        /// A plain, visible text field.
        case text
        /// An obscured field for secrets such as API keys.
        case secure
    }

    /// Stable identifier used as the dictionary key when collecting input.
    public let key: String
    /// Human-readable label shown next to the field.
    public let name: String
    /// The control style the UI should render.
    public let kind: Kind
    /// Placeholder text shown while the field is empty.
    public let placeholder: String
    /// Whether the field should be tucked away under an "Advanced" section.
    public let isAdvanced: Bool
    /// The value used when the user leaves the field untouched.
    public let defaultValue: String?

    public var id: String { key }

    public init(
        key: String,
        name: String,
        kind: Kind = .text,
        placeholder: String = "",
        isAdvanced: Bool = false,
        defaultValue: String? = nil
    ) {
        self.key = key
        self.name = name
        self.kind = kind
        self.placeholder = placeholder
        self.isAdvanced = isAdvanced
        self.defaultValue = defaultValue
    }
}

/// Errors thrown while turning collected form input into a concrete provider.
///
/// - Authored by: Claude Opus 4.8 (Anthropic)
public enum ProviderConfigurationError: LocalizedError {
    case missingField(String)
    case invalidValue(field: String, value: String)

    public var errorDescription: String? {
        switch self {
        case .missingField(let name):
            return "\(name) is required."
        case .invalidValue(let field, let value):
            return "\"\(value)\" is not a valid value for \(field)."
        }
    }
}
