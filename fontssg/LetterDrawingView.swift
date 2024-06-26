//
//  LetterDrawingView.swift
//  fontssg
//
//  Created by 안재원 on 5/22/24.
//

import Foundation
import PencilKit
import SwiftData
import SwiftUI

struct LetterDrawingView: View {
    @Environment(\.modelContext) var modelContext
    @Binding var canvas: PKCanvasView
    var project: Project
    var letterDrawing: LetterDrawing?
    @Binding var selectedUnicode: UnicodeValue?

    @State var isDirty = false
    @State var canUndo = false
    @State var canRedo = false

    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0

    var body: some View {
        NavigationStack {
            Group {
                ZStack {
                    // baseline
                    GeometryReader { proxy in
                        let baselineOffset = LetterDrawing.baselineOffset
                        Path { path in
                            path.move(to: .init(x: 0, y: baselineOffset))
                            path.addLine(to: .init(x: proxy.size.width, y: baselineOffset))
                        }
                        .stroke(.red, lineWidth: 5)
                    }
                    // Reference font
                    Text(String(selectedUnicode ?? 0))
                        .font(.system(size: LetterDrawing.unitsPerEm))
                        .foregroundColor(.gray.opacity(0.1))
                    LetterDrawingCanvas(
                        canvas: $canvas,
                        isDirty: $isDirty,
                        canUndo: $canUndo,
                        canRedo: $canRedo
                    )
                }
            }
            .frame(width: LetterDrawing.frame.width, height: LetterDrawing.frame.height)
            .background(.white)
            .scaleEffect(currentZoom + totalZoom)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        currentZoom = value.magnification - 1
                    }
                    .onEnded { _ in
                        totalZoom += currentZoom
                        currentZoom = 0
                    }
            )
            .accessibilityZoomAction { action in
                switch action.direction {
                case .zoomIn:
                    totalZoom += 0.1
                case .zoomOut:
                    totalZoom -= 0.1
                }
            }
            .shadow(color: .gray.opacity(0.3), radius: 10)
            .padding()
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    let previous = selectedUnicode?.previous
                    let next = selectedUnicode?.next
                    HStack {
                        Button(action: {
                            canUndo = false
                            canRedo = false
                            selectedUnicode = previous
                        }, label: {
                            Image(systemName: "arrow.left").imageScale(.large)
                        })
                        .disabled(previous == nil)
                        Button(action: {
                            canUndo = false
                            canRedo = false
                            selectedUnicode = next
                        }, label: {
                            Image(systemName: "arrow.right").imageScale(.large)
                        })
                        .disabled(next == nil)
                    }
                    HStack {
                        Button(action: {
                            canvas.drawing = PKDrawing()
                            isDirty = false
                            canUndo = false
                            canRedo = false
                            if let ld = letterDrawing {
                                modelContext.delete(ld)
                            }
                        }, label: {
                            Image(systemName: "trash").imageScale(.large)
                        }).disabled(letterDrawing == nil)
                        Button(action: {
                            canvas.undoManager?.undo()
                        }, label: {
                            Image(systemName: "arrow.uturn.backward").imageScale(.large)
                        }).disabled(!canUndo)
                        Button(action: {
                            canvas.undoManager?.redo()
                        }, label: {
                            Image(systemName: "arrow.uturn.forward").imageScale(.large)
                        }).disabled(!canRedo)
                    }
                }
            }
        }.onChange(of: selectedUnicode) { oldValue, _ in
            if let oldValue = oldValue {
                if isDirty && !canvas.drawing.strokes.isEmpty {
                    let oldDrawing = canvas.drawing
                    Task {
                        let newLd = try! LetterDrawing(
                            project: project,
                            unicode: oldValue,
                            drawing: oldDrawing
                        )
                        modelContext.insert(newLd)
                    }
                }
            }
            if let ld = letterDrawing {
                canvas.drawing = ld.drawing
            } else {
                canvas.drawing = PKDrawing()
            }
            canUndo = false
            canRedo = false
            isDirty = false
        }.onAppear {
            if let ld = letterDrawing {
                canvas.drawing = ld.drawing
            }
            isDirty = false
        }
    }
}

#Preview {
    let schema = Schema([Project.self, LetterDrawing.self])
    let modelConfiguration = ModelConfiguration(
        isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: schema,
        configurations: modelConfiguration
    )
    struct Preview: View {
        @State var canvas = PKCanvasView()
        @State var unicode: UnicodeValue? = "갊".unicodeScalars.first?.value
        var body: some View {
            LetterDrawingView(
                canvas: $canvas,
                project: Project(name: "Preview"),
                letterDrawing: nil,
                selectedUnicode: $unicode
            )
        }
    }
    return Preview()
        .modelContainer(container)
}
