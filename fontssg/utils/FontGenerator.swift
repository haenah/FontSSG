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
        letterDrawings: [LetterDrawing]
    ) throws -> Data {
        guard let context = JSContext(virtualMachine: jsVM) else {
            throw FontGeneratorError("Failed to create JSContext")
        }
        let jsSource = try! String(
            contentsOf: Bundle.main.url(forResource: "fontGenerator", withExtension: "js")!
        )
        context.evaluateScript(jsSource)
        for letterDrawing in letterDrawings {
            let glyph = letterDrawing.glyph
            context.evaluateScript("addGlyph(\(glyph.json))")
        }
        let output = context.evaluateScript("generateFont()")
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
