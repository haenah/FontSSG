//
//  fontssgApp.swift
//  fontssg
//
//  Created by 안재원 on 5/7/24.
//

import PencilKit
import SwiftData
import SwiftUI

@main
struct fontssgApp: App {
    let container = {
        let schema = Schema([Project.self, LetterDrawing.self])
        let container = try! ModelContainer(
            for: schema,
            configurations: ModelConfiguration(
            )
        )
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ProjectListView()
        }
        .modelContainer(container)
    }
}
