//
//  UTType+Supertype.swift
//  Minna
//
//  Created by Taylor Lineman on 6/17/26.
//

import UniformTypeIdentifiers

extension UTType {
    /// Returns the root types of this identifier
    var rootTypes: Set<UTType> {
        // If the super types are empty, then we are already a root type.
        if self.supertypes.isEmpty {
            return [self]
        }
        
        var roots = Set<UTType>()
        
        // When we find a supertype without any root types, add it to the roots.
        for supertype in self.supertypes where supertype.supertypes.isEmpty {
            roots.insert(supertype)
        }
        return roots
    }
}
