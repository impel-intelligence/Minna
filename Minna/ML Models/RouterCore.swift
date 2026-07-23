//
//  RouterCore.swift
//  Minna
//
//  Created by Taylor Lineman on 7/22/26.
//

import CoreML
import Logging

enum RouterOutput: String {
    case search
    case aiAssistant = "ai_assistant"
}

final class RouterCore {
    private var model: SearchRouter

    public init() throws {
        let config = MLModelConfiguration()
        // Xcode automatically generates the 'MyClassifier' class based on your file name
        self.model = try SearchRouter(configuration: config)
    }
    
    public func predict(_ text: String) throws -> RouterOutput? {
        let input = SearchRouterInput(text: text)
        let output = try model.prediction(input: input) // Safe to !bang! here because we checked to make sure it is not nil
        
        guard let classification = RouterOutput(rawValue: output.label) else {
            Log.logger.warning("Invalid Router Classification", metadata: ["classification": "\(output.label)"])
            return .none
        }
        
        return classification
    }
}
