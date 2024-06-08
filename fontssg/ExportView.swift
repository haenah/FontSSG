//
//  ExportView.swift
//  fontssg
//
//  Created by 안재원 on 6/7/24.
//

import Foundation
import SwiftUI
import WebKit

struct ExportView: UIViewRepresentable {
    var project: Project
    var letterDrawings: [LetterDrawing]

    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.navigationDelegate = context.coordinator
        return webview
    }

    func updateUIView(_ webview: WKWebView, context ctx: Context) {
        ctx.coordinator.parent.letterDrawings = letterDrawings
        webview.load(URLRequest(url: URL(string: "http://192.168.0.45")!))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKDownloadDelegate,
        UIDocumentInteractionControllerDelegate
    {
        var parent: ExportView

        init(_ parent: ExportView) {
            self.parent = parent
        }

        func webView(_ webview: WKWebView, didFinish _: WKNavigation!) {
            let project = parent.project
            let letterDrawings = project.letterDrawings
            webview.evaluateJavaScript("window.setFontName('\(project.name)')")
            for letterDrawing in letterDrawings {
                let glyph = letterDrawing.glyph
                webview.evaluateJavaScript("window.addGlyph(\(glyph.json))")
            }
            webview.evaluateJavaScript("window.downloadFont()")
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.request.url?.scheme == "blob" {
                return decisionHandler(.download)
            }
            return decisionHandler(.allow)
        }

        @available(iOS 14.5, *)
        func webView(
            _: WKWebView,
            navigationAction _: WKNavigationAction,
            didBecome download: WKDownload
        ) {
            download.delegate = self
        }

        @available(iOS 14.5, *)
        func download(
            _: WKDownload,
            decideDestinationUsing _: URLResponse,
            suggestedFilename: String,
            completionHandler: @escaping (URL?) -> Void
        ) {
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            let fileURL = documentsDirectory.appendingPathComponent(suggestedFilename)

            completionHandler(fileURL)
        }

        @available(iOS 14.5, *)
        func downloadDidFinish(_: WKDownload) {
            print("File Download Success")
        }

        @available(iOS 14.5, *)
        func download(_: WKDownload, didFailWithError error: Error, resumeData _: Data?) {
            print(error)
        }
    }
}
