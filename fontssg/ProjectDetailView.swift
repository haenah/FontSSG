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
                    let newLd = try! LetterDrawing(
                        project: project,
                        letterIndex: oldValue,
                        drawing: canvas.drawing
                    )
                    modelContext.insert(newLd)
                }
                canvas.drawing = PKDrawing()
            }
            selectedIdx = newVal
        }
    }

    @State var canvas = PKCanvasView()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn

    @State private var outputData: Data?

    var body: some View {
        let idxToLetterDrawing = Dictionary(
            uniqueKeysWithValues: letterDrawings.map {
                ($0.letterIndex, $0)
            }
        )
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: selectedIdxProxy) {
                ForEach(Array(Letter.allCategories.enumerated()), id: \.offset) { i, category in
                    Section(header: Text(category.name)) {
                        ForEach(Array(category.letters.enumerated().map {
                            (Letter.Index(i, $0.offset), $0.element)
                        }), id: \.0) { letterIndex, letter in
                            HStack {
                                Text(String(letter))
                                Spacer()
                                if let smallImage = idxToLetterDrawing[letterIndex]?.smallImage {
                                    smallImage
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
                    Button {
                        var newLds = letterDrawings
                        if let idx = selectedIdx {
                            if !canvas.drawing.strokes.isEmpty {
                                let newLd = try! LetterDrawing(
                                    project: project,
                                    letterIndex: idx,
                                    drawing: canvas.drawing
                                )
                                modelContext.insert(newLd)
                                if modelContext.hasChanges {
                                    try! modelContext.save()
                                }
                                canvas.drawing = PKDrawing()
                                newLds.append(newLd)
                            }
                        }
                        let data = try! FontGenerator.generateFont(
                            letterDrawings: newLds
                        )
                        outputData = data
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            })
        } detail: {
            if let sdx = selectedIdx {
                LetterDrawingView(
                    canvas: $canvas,
                    letterDrawing: idxToLetterDrawing[sdx],
                    selectedIdx: selectedIdxProxy
                ).background(.background)
            } else {
                Text("Select a letter")
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: Binding(
            get: { outputData != nil },
            set: { _ in outputData = nil }
        )) {
            if let outputData = outputData {
                ShareSheet(
                    project: project,
                    otfData: outputData
                )
            }
        }
    }
}

#Preview {
    let schema = Schema([Project.self])
    let modelConfiguration = ModelConfiguration(
        isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: schema,
        configurations: modelConfiguration
    )
    return ProjectDetailView(project: Project(name: "Preview"))
        .modelContainer(container)
}
