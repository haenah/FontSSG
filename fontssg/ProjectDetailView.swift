//
//  ProjectDetailView.swift
//  fontssg
//
//  Created by 안재원 on 5/21/24.
//

import Foundation
import PencilKit
import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext
    var project: Project
    @Query private var letterDrawings: [LetterDrawing]
    init(project: Project) {
        self.project = project
        let name = project.name
        let filter = #Predicate<LetterDrawing> { ld in
            ld.project.name == name
        }
        _letterDrawings = Query(filter: filter)
    }

    @State private var selectedIdx: Letter.Index? = .init(0, 0)
    /// A proxy for `selectedIdx` that saves the current drawing when the selection changes.
    var selectedIdxProxy: Binding<Letter.Index?> {
        Binding {
            selectedIdx
        } set: { newVal in
            if let oldValue = selectedIdx {
                if !canvas.drawing.strokes.isEmpty {
                    let newLd = LetterDrawing(
                        project: project,
                        letterIndex: oldValue,
                        drawing: canvas.drawing)
                    modelContext.insert(newLd)
                }
            }
            canvas.drawing = PKDrawing()
            selectedIdx = newVal
        }
    }

    var canvas = PKCanvasView()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: selectedIdxProxy) {
                ForEach(Array(Letter.allCategories.enumerated()), id: \.offset) { i, category in
                    let existingLetterDrawingsWithGivenCategoryIndex = letterDrawings.filter {
                        $0.letterIndex.category == i
                    }
                    Section(header: Text(category.name)) {
                        ForEach(Array(category.letters.enumerated().map { j, letter in
                            let existingLetterDrawing = existingLetterDrawingsWithGivenCategoryIndex.first {
                                $0.letterIndex.letter == j
                            }
                            return (Letter.Index(i, j), letter, existingLetterDrawing)
                        }), id: \.0) { _, letter, ld in
                            HStack {
                                Text(String(letter))
                                Spacer()
                                if let pngData = ld?.smallImage {
                                    Image(uiImage: UIImage(data: pngData)!)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .background(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(project.name)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {} label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            })
        } detail: {
            if let _ = selectedIdx {
                let letterDrawing = letterDrawings.first {
                    $0.letterIndex == selectedIdx
                }
                LetterDrawingView(
                    canvas: canvas,
                    letterDrawing: letterDrawing,
                    selectedIdx: selectedIdxProxy)
            } else {
                Text("Select a letter")
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    let schema = Schema([Project.self])
    let modelConfiguration = ModelConfiguration(
        isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: schema,
        configurations: modelConfiguration)
    return ProjectDetailView(project: Project(name: "Preview"))
        .modelContainer(container)
}
