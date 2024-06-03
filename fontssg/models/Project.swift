//
//  Project.swift
//  fontssg
//
//  Created by 안재원 on 5/20/24.
//

import Foundation
import SwiftData

@Model
final class Project: Equatable {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .cascade, inverse: \LetterDrawing.project) var letterDrawings: [LetterDrawing] = []

    init(name: String) {
        self.name = name
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.name == rhs.name
    }
}
