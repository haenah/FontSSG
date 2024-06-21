//
//  FontGenerator.swift
//  fontssg
//
//  Created by 안재원 on 6/14/24.
//

import Foundation
import JavaScriptCore

class FontGenerator {
    struct FontGeneratorError: Error {
        let message: String
        init(_ message: String) {
            self.message = message
        }
    }

    static let jsVM = JSVirtualMachine()
    static func generateFont(
        letterDrawings: [LetterDrawing],
        onProgress: ((Double) -> Void)?
    ) async throws -> Data {
        onProgress?(0)
        guard let context = JSContext(virtualMachine: jsVM) else {
            throw FontGeneratorError("Failed to create JSContext")
        }
        let jsSource = try! String(
            contentsOf: Bundle.main.url(forResource: "fontGenerator", withExtension: "js")!
        )
        context.evaluateScript(jsSource)
        for (i, ld) in letterDrawings.enumerated() {
            let glyph = String(data: ld.glyphJsonData, encoding: .utf8)!
            context.evaluateScript("addGlyph(\(glyph))")
            onProgress?(Double(i + 1) / Double(letterDrawings.count))
        }
        let output = context.evaluateScript("generateFont(\(Int(LetterDrawing.unitsPerEm)))")
        guard let ref = output?.jsValueRef
        else {
            throw FontGeneratorError("Failed to generate font")
        }
        let bytes = JSObjectGetArrayBufferBytesPtr(context.jsGlobalContextRef, ref, nil)
            .assumingMemoryBound(to: UInt8.self)
        let size = JSObjectGetArrayBufferByteLength(context.jsGlobalContextRef, ref, nil)
        return Data(bytes: bytes, count: size)
    }
}
