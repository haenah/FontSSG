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
        self.image = drawing.image(from: LetterDrawing.frame, scale: 1).pngData()!
        let bounds = drawing.bounds
        self.smallImage = drawing.image(
            from: LetterDrawing.frame,
            scale: 32 / bounds.width
        ).pngData()!
    }
}
