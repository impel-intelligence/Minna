//
//  Navigable.swift
//  Minna
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

protocol Navigable: View {
    associatedtype LabelContent: View
    static var label: LabelContent { get }
}
