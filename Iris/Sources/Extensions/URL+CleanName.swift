//
//  URL+CleanName.swift
//  BlurbKit
//
//  Created by Taylor Lineman on 6/18/26.
//

import Foundation

extension URL {
    func name() -> String {
        return self.deletingPathExtension().lastPathComponent
    }
}
