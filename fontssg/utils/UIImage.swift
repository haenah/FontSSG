//
//  UIImage.swift
//  fontssg
//
//  Created by 안재원 on 6/6/24.
//

import Foundation
import SwiftUI
import UIKit

extension UIImage {
    var grayscalePixelData: [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(
            data: &pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
        )
        guard let cgImage = cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        return pixelData
    }

    convenience init(grayscalePixelData: [UInt8], width: Int, height: Int) {
        let coloredPixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        defer { coloredPixelData.deallocate() }
        // TODO: Optimize image creation
        for i in 0 ..< width * height {
            coloredPixelData[i * 4] = 0
            coloredPixelData[i * 4 + 1] = 0
            coloredPixelData[i * 4 + 2] = 0
            coloredPixelData[i * 4 + 3] = grayscalePixelData[i]
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: CGDataProvider(data: CFDataCreate(
                nil,
                coloredPixelData,
                4 * width * height
            ))!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        self.init(cgImage: cgImage!)
    }
}
