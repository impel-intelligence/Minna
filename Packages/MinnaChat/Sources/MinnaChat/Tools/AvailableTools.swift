//
//  AvailableTools.swift
//  MinnaChat
//
//  Created by Taylor Lineman on 7/17/26.
//  Edited by Claude Opus 5 (Anthropic) on 2026-08-06: exposed getTool so out-of-module
//  callers (the ModelBench harness) can build the same tool set the app runs.
//

import AnyLanguageModel
import IrisSearch

public enum AvailableTool: Int, CaseIterable, Sendable {
    case getDocument
    case getExcerptContext
    case search
    case searchInDocument

    public func getTool(irisDB: IrisDB) -> any Tool {
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

