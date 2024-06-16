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
    @Binding var canvas: PKCanvasView
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        #if targetEnvironment(simulator)
        canvas.drawingPolicy = .anyInput
        #endif
        canvas.backgroundColor = .clear
        let color = PKInkingTool.convertColor(
            .black,
            from: .dark,
            to: .light
        )
        canvas.tool = PKInkingTool(
            .pen,
            color: color,
            width: 15
        )
        canvas.becomeFirstResponder()
        canvas.delegate = context.coordinator

        return canvas
    }

    func updateUIView(_: PKCanvasView, context _: Context) {}

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
        @State private var canUndo = false
        @State private var canRedo = false
        @State private var canvas = PKCanvasView()

        var body: some View {
            LetterDrawingCanvas(
                canvas: $canvas,
                canUndo: $canUndo,
                canRedo: $canRedo
            )
        }
    }
    return Preview()
}
