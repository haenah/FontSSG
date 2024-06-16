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
        let id = project.id
        let filter = #Predicate<LetterDrawing> { ld in
            ld.project.id == id
        }
        _letterDrawings = Query(filter: filter)
    }

    @State private var selectedUnicode: UnicodeValue? = CharacterCategory.allCases.first?.unicodes
        .first
    /// A proxy for `selectedIdx` that saves the current drawing when the selection changes.
    var selectedUnicodeProxy: Binding<UnicodeValue?> {
        Binding {
            selectedUnicode
        } set: { newVal in
            if let oldValue = selectedUnicode {
                if !canvas.drawing.strokes.isEmpty {
                    let newLd = try! LetterDrawing(
                        project: project,
                        unicode: oldValue,
                        drawing: canvas.drawing
                    )
                    modelContext.insert(newLd)
                }
                canvas.drawing = PKDrawing()
            }
            selectedUnicode = newVal
        }
    }

    @State var canvas = PKCanvasView()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn

    @State private var progress: Double? = nil
    @State private var outputData: Data?

    var body: some View {
        let unicodeToDrawing = Dictionary(
            uniqueKeysWithValues: letterDrawings.map {
                ($0.unicode, $0)
            }
        )
        return NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: selectedUnicodeProxy) {
                ForEach(CharacterCategory.allCases, id: \.name) { category in
                    Section(header: Text(category.name)) {
                        ForEach(category.unicodes, id: \.self) { unicode in
                            HStack {
                                Text(String(unicode))
                                Spacer()
                                if let smallImage = unicodeToDrawing[unicode]?.smallImage {
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
                    if progress != nil {
                        ProgressView()
                    } else {
                        Button {
                            Task {
                                var newLds = letterDrawings
                                if let unicode = selectedUnicode {
                                    if !canvas.drawing.strokes.isEmpty {
                                        let newLd = try! LetterDrawing(
                                            project: project,
                                            unicode: unicode,
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
                                let data = try! await FontGenerator.generateFont(
                                    letterDrawings: newLds,
                                    onProgress: { progress in
                                        self.progress = progress
                                    }
                                )
                                progress = nil
                                outputData = data
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            })
        } detail: {
            if let unicode = selectedUnicode {
                LetterDrawingView(
                    canvas: $canvas,
                    letterDrawing: unicodeToDrawing[unicode],
                    selectedUnicode: selectedUnicodeProxy
                ).background(.background)
            } else {
                Text("Select a letter")
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: Binding(
            get: {
                progress != nil || outputData != nil
            },
            set: { _ in
                progress = nil
                outputData = nil
            }
        )) {
            if let progress = progress {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 30)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 30, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                }
                .frame(
                    maxWidth: 300,
                    maxHeight: 300
                )
                .scaledToFit()
                .padding()
            } else if let outputData = outputData {
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
