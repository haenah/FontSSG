//
//  OTF.swift
//  fontssg
//
//  Created by 안재원 on 6/7/24.
//

import Foundation
import UIKit

struct Glyph: Encodable {
    static let jsonEncoder = JSONEncoder()
    enum Contour: Encodable {
        case M(x: Double, y: Double)
        case L(x: Double, y: Double)
        case C(x1: Double, y1: Double, x2: Double, y2: Double, x: Double, y: Double)
        case Z
    }

    struct InitError: Error {}

    var name: String
    var unicode: UnicodeValue
    var top: Int
    var bottom: Int
    var advanceWidth: Int
    var contours: [Contour]

    init(
        unicode: UnicodeValue,
        image: UIImage,
        top: Double,
        bottom: Double,
        baselineOffset: Double
    ) throws {
        name = String(unicode)
        self.unicode = unicode
        self.top = Int(baselineOffset - top)
        self.bottom = Int(baselineOffset - bottom)
        let width = Int(image.size.width), height = Int(image.size.height)
        guard let pixels = image.grayscalePixelData else {
            throw InitError()
        }
        let binarized: [UInt8] = pixels.map { $0 < 128 ? 1 : 0 }
        let potrace = Potrace(bm: .init(width: width, height: height, data: binarized))
        potrace.process()
        advanceWidth = width
        contours = potrace.getContours(baselineOffset: baselineOffset)
    }

    var jsonData: Data {
        let data = try! Self.jsonEncoder.encode(self)
        return data
    }
}

extension Potrace {
    func getContours(
        baselineOffset h: Double
    ) -> [Glyph.Contour] {
        var contours = [Glyph.Contour]()
        let n = pathlist.count
        for i in 1 ..< n {
            let path = pathlist[i]
            let curve = path.curve
            let n = curve.n
            contours.append(.M(
                x: curve.c[(n - 1) * 3 + 2].x,
                y: h - curve.c[(n - 1) * 3 + 2].y
            ))
            for i in 0 ..< n {
                if curve.tag[i] == "CURVE" {
                    contours.append(.C(
                        x1: curve.c[i * 3 + 0].x,
                        y1: h - curve.c[i * 3 + 0].y,
                        x2: curve.c[i * 3 + 1].x,
                        y2: h - curve.c[i * 3 + 1].y,
                        x: curve.c[i * 3 + 2].x,
                        y: h - curve.c[i * 3 + 2].y
                    ))
                } else if curve.tag[i] == "CORNER" {
                    contours.append(.L(
                        x: curve.c[i * 3 + 1].x,
                        y: h - curve.c[i * 3 + 1].y
                    ))
                    contours.append(.L(
                        x: curve.c[i * 3 + 2].x,
                        y: h - curve.c[i * 3 + 2].y
                    ))
                }
            }
        }
        return contours
    }
}
