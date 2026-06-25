//
//  FolderViewMode.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

import ViewStorage

enum FolderViewMode: Int, CaseIterable, CustomStringConvertible, ViewStorable {
    case grid
    case list
    
    var description: String {
        switch self {
        case .grid:
            return "Grid"
        case .list:
            return "List"
        }
    }
}
