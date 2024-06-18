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

    var body: some View {
        NavigationStack {
            Group {
                ZStack {
                    // baseline
                    GeometryReader { proxy in
                        let baseline = proxy.frame(in: .local).height * 0.8
                        Path { path in
                            path.move(to: .init(x: 0, y: baseline))
                            path.addLine(to: .init(x: proxy.size.width, y: baseline))
                        }
                        .stroke(.red, lineWidth: 5)
                    }
                    // Reference font
                    Text(String(selectedUnicode!))
                        .font(.system(size: 1000)
                        .lineLimit(1)
                        .lineSpacing(0)
                        .minimumScaleFactor(0.001)
                        .foregroundColor(.gray.opacity(0.3))
                        .scaledToFit()
                    LetterDrawingCanvas(
                        canvas: $canvas,
                        isDirty: $isDirty,
                        canUndo: $canUndo,
                        canRedo: $canRedo
                    )
                    .frame(
                        width: LetterDrawing.frame.width,
                        height: LetterDrawing.frame.height
                    )
                    .scaledToFit()
                }
            }
            .frame(maxWidth: 250, maxHeight: 250)
            .aspectRatio(1, contentMode: .fit)
            .background(.white)
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
                if isDirty {
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
