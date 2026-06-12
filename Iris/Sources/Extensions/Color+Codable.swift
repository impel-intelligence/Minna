//
//  Color+Codable.swift
//  Iris
//
//  Created by Taylor Lineman on 6/12/26.
//

import SwiftUI

extension Color: @retroactive Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        self = try Color(data: data)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(try self.toData())
    }
}

/// Attribution: https://nilcoalescing.com/blog/EncodeAndDecodeSwiftUIColor/
extension Color {
    enum ColorDecodingError: Error {
        case wrongType
    }
    
    func toData() throws -> Data {
        let platformColor = NSColor(self)
        return try NSKeyedArchiver.archivedData(
            withRootObject: platformColor,
            requiringSecureCoding: true
        )
    }
    
    init(data: Data) throws {
        guard let platformColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            throw ColorDecodingError.wrongType
        }
        
        self = Color(nsColor: platformColor)
    }
}
