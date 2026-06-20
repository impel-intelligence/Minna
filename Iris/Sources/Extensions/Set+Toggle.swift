//
//  Set+Toggle.swift
//  Iris
//
//  Created by Taylor Lineman on 6/18/26.
//

import Collections

extension Set {
    mutating func toggle(_ item: Set.Element) {
        if self.contains(item) {
            self.remove(item)
        } else {
            self.insert(item)
        }
    }
}

extension OrderedSet {
    mutating func toggle(_ item: OrderedSet.Element) {
        if self.contains(item) {
            self.remove(item)
        } else {
            self.append(item)
        }
    }
}
