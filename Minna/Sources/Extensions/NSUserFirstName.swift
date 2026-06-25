//
//  NSUserFirstName.swift
//  Iris
//
//  Created by Taylor Lineman on 6/23/26.
//

import Cocoa

func NSUserFirstName() -> String {
    let name = NSFullUserName()
    let splits = name.components(separatedBy: " ")
    let firstName = splits.first
    return firstName ?? name
}
