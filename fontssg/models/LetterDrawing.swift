//
//  LetterDrawing.swift
//  fontssg
//
//  Created by 안재원 on 5/23/24.
//

import Foundation
import PencilKit
import SwiftData

@Model
final class LetterDrawing {
    static let frame = CGRect(origin: .zero, size: .init(width: 512, height: 512))
    @Attribute(.unique) var id = UUID()
    @Relationship var project: Project
    var letterIndex: Letter.Index
    var image: Data
    var smallImage: Data

    init(id: UUID = UUID(), project: Project, letterIndex: Letter.Index, drawing: PKDrawing) {
        self.id = id
        self.project = project
        self.letterIndex = letterIndex
        let bounds = drawing.bounds
        let imageBounds = CGRect(
            x: bounds.minX - 16,
            y: LetterDrawing.frame.minY,
            width: bounds.width + 32,
            height: LetterDrawing.frame.height
        )
        let image = drawing.image(from: imageBounds, scale: 1)
        self.image = image.pngData()!
        self.smallImage = UIGraphicsImageRenderer(
            size: .init(
                width: imageBounds.width * 32 / imageBounds.height,
                height: 32
            )
        ).pngData { ctx in
            image.draw(in: .init(origin: .zero, size: ctx.format.bounds.size))
        }
    }
}
