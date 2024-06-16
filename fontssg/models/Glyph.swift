//
//  OTF.swift
//  fontssg
//
//  Created by 안재원 on 6/7/24.
//

import Foundation

struct Glyph: Encodable {
    enum Contour: Encodable {
        case M(x: Double, y: Double)
        case L(x: Double, y: Double)
        case C(x1: Double, y1: Double, x2: Double, y2: Double, x: Double, y: Double)
        case Z
    }

    var name: String
    var unicode: UnicodeValue
    var advanceWidth: Int
    var contours: [Contour]

    var json: String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}
