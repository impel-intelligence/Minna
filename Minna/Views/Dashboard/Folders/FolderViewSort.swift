//
//  FolderViewSort.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

import ViewStorage
import Foundation

enum FolderViewSort: Int, CaseIterable, CustomStringConvertible, ViewStorable {
    case mostRecent
    case leastRecent
    case az
    case za
    
    var description: String {
        switch self {
        case .mostRecent:
            return "Most Recent"
        case .leastRecent:
            return "Least Recent"
        case .az:
            return "A-Z"
        case .za:
            return "Z-A"
        }
    }
    
    var sortDescriptor: SortDescriptor<File> {
        switch self {
        case .mostRecent:
            return SortDescriptor(\.createdAt, order: .forward)
        case .leastRecent:
            return SortDescriptor(\.createdAt, order: .reverse)
        case .az:
            return SortDescriptor(\.title, order: .forward)
        case .za:
            return SortDescriptor(\.title, order: .reverse)
        }
    }
    
    func sortFunction(lhs: File, rhs: File) -> Bool {
        switch self {
        case .mostRecent:
            return lhs.createdAt.compare(rhs.createdAt) == .orderedDescending
        case .leastRecent:
            return lhs.createdAt.compare(rhs.createdAt) == .orderedAscending
        case .az:
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        case .za:
            return lhs.title.localizedCompare(rhs.title) == .orderedDescending
        }
    }
}
