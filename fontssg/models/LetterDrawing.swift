//
//  LetterDrawing.swift
//  fontssg
//
//  Created by 안재원 on 5/23/24.
//

import Foundation
import PencilKit
import SwiftData
import SwiftUI

@Model
final class LetterDrawing {
    static let frame = CGRect(origin: .zero, size: .init(width: 250, height: 250))
    @Attribute(.unique) var id: UUID
    @Relationship var project: Project
    var unicode: UnicodeValue
    @Attribute(.externalStorage) private var imageData: ImageData
    private var smallImageData: Data

    struct ImageData: Codable {
        var width: Int
        var height: Int
        var pixels: [UInt8]
        init(uiImage: UIImage) {
            width = Int(uiImage.size.width)
            height = Int(uiImage.size.height)
            pixels = uiImage.grayscalePixelData!
        }
    }

    struct InitError: Error {}

    init(
        id: UUID = UUID(),
        project: Project,
        unicode: UnicodeValue,
        drawing: PKDrawing
    ) throws {
        self.id = id
        self.project = project
        self.unicode = unicode
        let bounds = drawing.bounds
        let imageBounds = CGRect(
            x: max(LetterDrawing.frame.minX, bounds.minX - 10),
            y: LetterDrawing.frame.minY,
            width: min(LetterDrawing.frame.width, bounds.width + 20),
            height: LetterDrawing.frame.height
        )
        let image = drawing.image(from: imageBounds, scale: 1)
        imageData = .init(uiImage: image)
        smallImageData = UIGraphicsImageRenderer(
            size: .init(
                width: imageBounds.width * 32 / imageBounds.height,
                height: 32
            )
        ).pngData { ctx in
            image.draw(in: .init(origin: .zero, size: ctx.format.bounds.size))
        }
    }

    var image: Image {
        .init(uiImage: .init(
            grayscalePixelData: imageData.pixels, width: Int(imageData.width),
            height: Int(imageData.height)
        ))
    }

    var smallImage: Image {
        .init(uiImage: .init(data: smallImageData)!)
    }

    var glyph: Glyph {
        let width = imageData.width
        let height = imageData.height
        let pixels = imageData.pixels
        let binarized: [UInt8] = pixels.map { $0 < 128 ? 1 : 0 }
        let potrace = Potrace(bm: .init(width: width, height: height, data: binarized))
        potrace.process()
        return Glyph(
            name: String(unicode),
            unicode: unicode,
            advanceWidth: width,
            contours: potrace.contours
        )
    }
}
