//
//  CGPoint+Math.swift
//  Minna
//
//  Created by Taylor Lineman on 8/28/26.
//

import CoreGraphics

extension CGPoint {
    func translate(by translation: CGSize) -> CGPoint {
        return CGPoint(x: x + translation.width, y: y + translation.height)
    }
    
    static func / (lhs: Self, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    static func * (lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
