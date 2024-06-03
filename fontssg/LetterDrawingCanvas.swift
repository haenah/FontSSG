//
//  LetterDrawingCanvas.swift
//  fontssg
//
//  Created by 안재원 on 5/23/24.
//

import Foundation
import PencilKit
import SwiftUI

struct LetterDrawingCanvas: UIViewRepresentable {
    var canvas: PKCanvasView
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        #if targetEnvironment(simulator)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        #endif
        canvas.tool = PKInkingTool(.pen, color: .black, width: 10)
        canvas.becomeFirstResponder()
        canvas.delegate = context.coordinator

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: LetterDrawingCanvas

        init(_ parent: LetterDrawingCanvas) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.canUndo = canvasView.undoManager?.canUndo ?? false
            parent.canRedo = canvasView.undoManager?.canRedo ?? false
        }
    }
}

#Preview {
    struct Preview: View {
        var project = Project(name: "Test")
        @State private var selectedIdx: Letter.Index = .init(0, 0)
        @State private var canUndo = false
        @State private var canRedo = false
        private var canvas = PKCanvasView()

        var body: some View {
            VStack {
                Text(String(Letter[selectedIdx])).font(.title)
                LetterDrawingCanvas(
                    canvas: canvas,
                    canUndo: $canUndo,
                    canRedo: $canRedo
                )
                .frame(maxWidth: 512, maxHeight: 512)
                .aspectRatio(1, contentMode: .fit)
                .background(.white)
                .shadow(color: .gray.opacity(0.3), radius: 10)
                .padding()
                HStack {
                    Button {
                        if let next = selectedIdx.next {
                            selectedIdx = next
                        }
                    } label: {
                        Text("Next")
                    }.font(.title)
                    Button {
                        if let previous = selectedIdx.previous {
                            selectedIdx = previous
                        }
                    } label: {
                        Text("Previous")
                    }.font(.title)
                    Button {
                        canvas.drawing = PKDrawing()
                    } label: {
                        Text("Reset")
                    }.font(.title)
                }
            }
        }
    }
    return Preview()
}
