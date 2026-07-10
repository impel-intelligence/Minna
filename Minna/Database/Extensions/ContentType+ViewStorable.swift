//
//  ContentType+ViewStorable.swift
//  Minna
//
//  Created by Taylor Lineman on 6/30/26.
//

import Foundation
import ViewStorage
import DatabaseSchema

extension ContentType: @retroactive ViewStorable {
    public static func read(from store: UserDefaults, forKey key: String) -> ContentType? {
        (store.object(forKey: key) as? Int).flatMap({ ContentType(rawValue: $0) })
    }
    
    public func write(to store: UserDefaults, forKey key: String) {
        store.set(rawValue, forKey: key)
    }
}
