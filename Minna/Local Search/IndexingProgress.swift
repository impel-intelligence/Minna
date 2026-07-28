//
//  IndexingProgress.swift
//  Minna
//
//  Created by Taylor Lineman on 7/27/26.
//

import Foundation

struct IndexingProgress {
    var completed: Set<UUID> = []
    var inProgress: Set<UUID> = []
    
    var total: Int { completed.count + inProgress.count }
    
    var fractionCompleted: Double { total == 0 ? 1 : Double(completed.count) / Double(total) }
    var isIndexing: Bool { !inProgress.isEmpty }
    
    mutating func add(id: UUID) {
        inProgress.insert(id)
    }
    
    mutating func complete(id: UUID) {
        // If this id does not exist in the inProgress array, it has been canceled and we don't want to set it to be true.
        guard inProgress.contains(id) else { return }
        
        inProgress.remove(id)
        completed.insert(id)
        
        // Reset the indexing
        if inProgress.isEmpty {
            completed.removeAll()
            inProgress.removeAll()
        }
    }
    
    mutating func cancel(id: UUID) {
        inProgress.remove(id)
        completed.remove(id)
        
        // Reset the indexing
        if inProgress.isEmpty {
            completed.removeAll()
            inProgress.removeAll()
        }
    }
}
