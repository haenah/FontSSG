//
//  ShareView.swift
//  fontssg
//
//  Created by 안재원 on 6/9/24.
//

import Foundation
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var project: Project
    var activityItem: UIActivityItemSource

    init(project: Project, otfData: Data) {
        self.project = project
        activityItem = DataActivityItemSource(project: project, data: otfData)
    }

    final class DataActivityItemSource: NSObject, UIActivityItemSource {
        var project: Project
        var data: Data

        init(project: Project, data: Data) {
            self.project = project
            self.data = data
            super.init()
        }

        func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
            return URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("\(project.name).otf")
        }

        func activityViewController(
            _: UIActivityViewController,
            itemForActivityType _: UIActivity.ActivityType?
        ) -> Any? {
            return data
        }

        func activityViewController(
            _: UIActivityViewController,
            subjectForActivityType _: UIActivity.ActivityType?
        ) -> String {
            return project.name
        }

        func activityViewController(
            _: UIActivityViewController,
            dataTypeIdentifierForActivityType _: UIActivity.ActivityType?
        ) -> String {
            return "public.opentype-font"
        }

        func activityViewController(
            _: UIActivityViewController,
            thumbnailImageForActivityType _: UIActivity.ActivityType?,
            suggestedSize _: CGSize
        ) -> UIImage? {
            return UIImage(systemName: "doc")
        }
    }

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [activityItem],
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
