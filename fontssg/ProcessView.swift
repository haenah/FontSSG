//
//  ExportView.swift
//  fontssg
//
//  Created by 안재원 on 6/7/24.
//

import Foundation
import SwiftUI
import WebKit

struct ProcessView: UIViewRepresentable {
    var project: Project
    var letterDrawings: [LetterDrawing]
    var afterDownload: (_ fileURL: URL?) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.navigationDelegate = context.coordinator
        webview.load(URLRequest(url: URL(string: "http://192.168.0.45")!))
        return webview
    }

    func updateUIView(_: WKWebView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKDownloadDelegate,
        UIDocumentInteractionControllerDelegate
    {
        var parent: ProcessView
        var fileURL: URL?

        init(_ parent: ProcessView) {
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
            // Check if file already exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("Failed to remove existing file: \(error)")
                    completionHandler(nil)
                    return
                }
            }
            self.fileURL = fileURL
            completionHandler(fileURL)
        }

        @available(iOS 14.5, *)
        func downloadDidFinish(_: WKDownload) {
            if let fileURL = fileURL {
                self.fileURL = nil
                parent.afterDownload(fileURL)
            }
        }

        @available(iOS 14.5, *)
        func download(_: WKDownload, didFailWithError _: Error, resumeData _: Data?) {
            fileURL = nil
            parent.afterDownload(nil)
        }
    }
}
