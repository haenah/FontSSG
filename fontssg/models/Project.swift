//
//  Project.swift
//  fontssg
//
//  Created by 안재원 on 5/20/24.
//

import CoreText
import Foundation
import SwiftData

@Model
final class Project: Equatable {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(
        deleteRule: .cascade,
        inverse: \LetterDrawing.project
    ) var letterDrawings: [LetterDrawing]

    init(id: UUID = UUID(), name: String, letterDrawings: [LetterDrawing] = []) {
        self.id = id
        self.name = name
        self.letterDrawings = letterDrawings
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.name == rhs.name
    }
}
