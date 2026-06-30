//
//  MinnaContext.swift
//  Minna
//
//  Created by Taylor Lineman on 6/18/26.
//

import SwiftUI
import SentrySwift
import IrisSearch
import DatabaseSchema

enum IrisContextError: Error {
    case notConnected
}

/// A wrapper for IrisDBController that allows for easy insertion into SwiftUI's environment.
public struct IrisContext {
    private let controllerResult: Result<IrisDBController, IrisContextError>
        
    init(controllerResult: Result<IrisDBController, IrisContextError>) {
        self.controllerResult = controllerResult
    }
    
    private var controller: IrisDBController {
        get throws {
            try controllerResult.get()
        }
    }
    
    func isConnected() -> Bool {
        do {
            _ = try controller
            return true
        } catch {
            SentrySDK.capture(message: "Failed to create IrisDBController.")
            return false
        }
    }
    
    @MainActor
    var database: IrisDB {
        get throws {
            try controller.irisDB
        }
    }
    
    @MainActor
    var indexingProgress: IndexingProgress? {
        try? controller.indexingProgress
    }

    @MainActor
    func search(query: String) async throws -> [UUID] {
        return try await controller.search(query: query)
    }
        
    @MainActor
    func insert(_ file: File) throws {
        try controller.insert(file)
    }
    
    @MainActor
    func delete(_ file: File) throws {
        try controller.delete(file)
    }
    
    @MainActor
    func reIndex(_ file: File) throws {
        // If an existing index exists, delete it first
        try? controller.delete(file)
        // Re-index
        try controller.insert(file)
    }
}

extension IrisContext {
    /// A default value for `@Environment(\.irisContext)` that will always throw ``IrisContextError/notConnected``.
    ///
    /// A user must replace `@Environment(\.irisContext)` with their own ``IrisContext`` to remove this instance.
    public static var notConnected: IrisContext {
        self.init(controllerResult: .failure(IrisContextError.notConnected))
    }
}

extension EnvironmentValues {
    @Entry var irisContext: IrisContext = IrisContext.notConnected
}

extension View {
    func irisContext(_ irisContext: IrisContext) -> some View {
        environment(\.irisContext, irisContext)
    }
}

extension Scene {
    func irisContext(_ irisContext: IrisContext) -> some Scene {
        environment(\.irisContext, irisContext)
    }
}
