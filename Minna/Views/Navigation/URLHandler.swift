//
//  URLHandler.swift
//  Minna
//
//  Created by Taylor Lineman on 7/9/26.
//

import Foundation
import SwiftData
import DatabaseSchema

struct URLHandler {
    enum HandlingError: Error {
        case notAMinnaURL
        case noComponents
        case noActions
        case unsupportedAction
    }
    
    enum OpenDocumentActionError: Error {
        case invalidUUID
        case noDocumentWithUUID(uuid: UUID)
    }
    
    /// Handles incoming URLs, performing validation before any actions are taken.
    static func handle(_ url: URL, context: ModelContext, router: NavigationRouter) throws {
        guard url.scheme == "minna" else { throw HandlingError.notAMinnaURL }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw HandlingError.noComponents }
        
        // Ensure that the action we are taking is opening a document
        guard let action = components.host else {
            throw HandlingError.noActions
        }
        
        // Check if this is the docs action.
        if action == "doc" {
            return try handleDocURL(components, context: context, router: router)
        }
          
        // If we never returned from an action, throw an unsupported action error.
        throw HandlingError.unsupportedAction
    }
    
    private static func handleDocURL(_ components: URLComponents, context: ModelContext, router: NavigationRouter) throws {
        // Find the UUID of the document we want to open.
        let cleanedPath = components.path.replacingOccurrences(of: "/", with: "")
        guard let uuid = UUID(uuidString: cleanedPath) else {
            throw OpenDocumentActionError.invalidUUID
        }
        
        var descriptor = FetchDescriptor<File>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1
        let folders = try context.fetch(descriptor)
        guard let fileToOpen = folders.first else { throw OpenDocumentActionError.noDocumentWithUUID(uuid: uuid) }
        
        print("Open file \(fileToOpen.title)")
        
    }
}
