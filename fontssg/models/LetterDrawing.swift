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
    @Attribute(.unique) var id: String
    @Relationship var project: Project
    var unicode: UnicodeValue
    @Attribute(.externalStorage) private var drawingData: Data
    @Attribute(.externalStorage) var glyphJsonData: Data
    private var smallImageData: Data

    init(
        project: Project,
        unicode: UnicodeValue,
        drawing: PKDrawing
    ) throws {
        id = project.id.uuidString + String(unicode)
        self.project = project
        self.unicode = unicode
        drawingData = drawing.dataRepresentation()
        let bounds = drawing.bounds
        let imageBounds = CGRect(
            x: max(LetterDrawing.frame.minX, bounds.minX - 10),
            y: LetterDrawing.frame.minY,
            width: min(LetterDrawing.frame.width, bounds.width + 20),
            height: LetterDrawing.frame.height
        )
        let image = drawing.image(from: imageBounds, scale: 1, userInterfaceStyle: .light)
        smallImageData = UIGraphicsImageRenderer(
            size: .init(
                width: imageBounds.width * 32 / imageBounds.height,
                height: 32
            )
        ).pngData { ctx in
            image.draw(in: ctx.format.bounds)
        }
        glyphJsonData = try Glyph(unicode: unicode, image: image).jsonData
    }

    var drawing: PKDrawing {
        try! PKDrawing(data: drawingData)
    }

    var smallImage: Image {
        .init(uiImage: .init(data: smallImageData)!)
    }
}

extension PKDrawing {
    func image(
        from rect: CGRect,
        scale: CGFloat,
        userInterfaceStyle: UIUserInterfaceStyle
    ) -> UIImage {
        let currentTraits = UITraitCollection.current
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        let image = self.image(from: rect, scale: scale)
        UITraitCollection.current = currentTraits
        return image
    }
}
