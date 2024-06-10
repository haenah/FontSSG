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
    var letterDrawing: LetterDrawing?
    @Binding var selectedIdx: Letter.Index?

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
                    if let letterDrawing = letterDrawing {
                        letterDrawing.image.scaledToFit()
                    } else {
                        LetterDrawingCanvas(
                            canvas: $canvas,
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
            }
            .frame(maxWidth: 250, maxHeight: 250)
            .aspectRatio(1, contentMode: .fit)
            .background(.white)
            .shadow(color: .gray.opacity(0.3), radius: 10)
            .padding()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(Letter[selectedIdx!]))
                        .font(.title)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    let previous = selectedIdx?.previous
                    let next = selectedIdx?.next
                    HStack {
                        Button(action: {
                            canUndo = false
                            canRedo = false
                            selectedIdx = previous
                        }, label: {
                            Image(systemName: "arrow.left")
                        })
                        .disabled(previous == nil)
                        Button(action: {
                            canUndo = false
                            canRedo = false
                            selectedIdx = next
                        }, label: {
                            Image(systemName: "arrow.right")
                        })
                    }
                    if let ld = letterDrawing {
                        Button(action: {
                            canvas.drawing = PKDrawing()
                            modelContext.delete(ld)
                        }, label: {
                            Image(systemName: "trash")
                        })
                    } else {
                        HStack {
                            Button(action: {
                                canvas.undoManager?.undo()
                            }, label: {
                                Image(systemName: "arrow.uturn.backward")
                            }).disabled(!canUndo)
                            Button(action: {
                                canvas.undoManager?.redo()
                            }, label: {
                                Image(systemName: "arrow.uturn.forward")
                            }).disabled(!canRedo)
                        }
                    }
                }
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
        @State var selectedIdx: Letter.Index? = .init(6, 6)
        var body: some View {
            LetterDrawingView(
                canvas: $canvas,
                letterDrawing: nil,
                selectedIdx: $selectedIdx
            )
        }
    }
    return Preview()
        .modelContainer(container)
}
