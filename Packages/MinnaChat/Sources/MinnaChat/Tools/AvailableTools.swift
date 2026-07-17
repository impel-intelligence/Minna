//
//  AvailableTools.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/17/26.
//

import AnyLanguageModel
import IrisSearch

public enum AvailableTool: Int, CaseIterable {
    case getDocument
    case getExcerptContext
    case search
    case searchInDocument
    
    func getTool(irisDB: IrisDB) -> any Tool {
        switch self {
        case .getDocument:
            return GetDocumentTool(database: irisDB)
        case .getExcerptContext:
            return GetExcerptContextTool(database: irisDB)
        case .search:
            return SearchTool(database: irisDB)
        case .searchInDocument:
            return SearchInDocumentTool(database: irisDB)
        }
    }
}

