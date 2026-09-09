//
//  CGPoint+Math.swift
//  Minna
//
//  Created by Taylor Lineman on 8/28/26.
//  Edited by Claude Fable 5 (Anthropic) on 2026-09-08
//

import CoreGraphics

extension CGPoint {
    func translate(by translation: CGSize) -> CGPoint {
        return CGPoint(x: x + translation.width, y: y + translation.height)
    }

    func distanceSquared(to other: CGPoint) -> CGFloat {
        return (x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)
    }

    func distance(to other: CGPoint) -> CGFloat {
        return sqrt(distanceSquared(to: other))
    }

    static func + (lhs: Self, rhs: Self) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: Self, rhs: Self) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func / (lhs: Self, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    static func * (lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
