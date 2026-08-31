//
//  CGSize+Math.swift
//  Minna
//
//  Created by Taylor Lineman on 8/28/26.
//

import CoreGraphics

extension CGSize {
    static func + (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func - (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    static func * (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    static func / (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }
}
