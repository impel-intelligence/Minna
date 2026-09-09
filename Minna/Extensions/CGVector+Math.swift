//
//  CGVector+Math.swift
//  Minna
//
//  Created by Claude Fable 5 (Anthropic) on 2026-09-08.
//

import CoreGraphics

extension CGVector {
    static func + (lhs: Self, rhs: Self) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs.dx += rhs.dx
        lhs.dy += rhs.dy
    }

    static func * (lhs: Self, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }
}
