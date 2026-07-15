//
//  ModelProvider.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/1/26.
//  Edited by Claude Opus 4.8 (Anthropic) on 2026-07-01.
//

import Foundation
import AnyLanguageModel
import DatabaseSchema

public protocol ModelProvider: Sendable {
    /// The provider's identifier.
    static var id: String { get }
    
    static var editable: Bool { get }
    
    /// The fields the user must fill in to configure this provider. The settings
    /// form renders these dynamically and collects input keyed by ``ProviderField/key``.
    static var fields: [ProviderField] { get }
    
    /// Builds a configured provider from the values the user entered in the form.
    ///
    /// - Parameter values: Field input keyed by ``ProviderField/key``.
    /// - Returns: A ready-to-use provider.
    /// - Throws: ``ProviderConfigurationError`` when required input is missing or invalid.
    /// - Authored by: Claude Opus 4.8 (Anthropic)
    static func make(from values: [String: String]) throws -> Self
    
    static func make(from configuration: ConfiguredProvider) throws -> Self
    
    /// Creates a LanguageModel instance for the model with the given `id`.
    /// - Parameter id: The `id` of the model (ex: sonnet-5)
    /// - Returns: A ``LanguageModel``
    func getModel(id: String) -> any LanguageModel
    
    /// List all models that this provider offers.
    /// - Returns: A list of model ids  that are available.
    func availableModels() async throws -> [ModelManager.Model]
}
