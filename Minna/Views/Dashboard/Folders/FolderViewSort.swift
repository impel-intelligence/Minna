//
//  FolderViewSort.swift
//  Minna
//
//  Created by Taylor Lineman on 6/18/26.
//

import ViewStorage
import Foundation
import DatabaseSchema

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
            // Used to use localizedCompare, but it was a much slower process
            return lhs.title.compare(rhs.title) == .orderedAscending
        case .za:
            // Used to use localizedCompare, but it was a much slower process
            return lhs.title.compare(rhs.title) == .orderedDescending
        }
    }
    
    /// Computing the title and created values is expensive. This uses a Schwartzian transform to compute those values once.
    func sort(_ files: [File]) -> [File] {
        switch self {
        case .mostRecent:
            files
                .map { ($0, $0.createdAt)}
                .sorted { $0.1 > $1.1 }
                .map(\.0)
        case .leastRecent:
            files
                .map { ($0, $0.createdAt)}
                .sorted { $0.1 < $1.1 }
                .map(\.0)
        case .az:
            files
                .map { ($0, $0.title)}
                .sorted { $0.1.localizedCompare($1.1) == .orderedAscending }
                .map(\.0)
        case .za:
            files
                .map { ($0, $0.title)}
                .sorted { $0.1.localizedCompare($1.1) == .orderedDescending }
                .map(\.0)
        }
    }
}

