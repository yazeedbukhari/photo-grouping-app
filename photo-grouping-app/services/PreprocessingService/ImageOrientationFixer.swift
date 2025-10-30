//
//  ImageOrientationFixer.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import CoreGraphics
import ImageIO

enum ImageOrientationFixer {
    /// Returns a new CGImage that is drawn upright (top=Up, left=Left) according to the provided EXIF orientation.
    /// - Parameters:
    ///   - cg: The source CGImage (which itself does not carry orientation metadata).
    ///   - orientation: The EXIF/HEIC orientation the pixels should be interpreted with.
    /// - Returns: A new CGImage with pixels rendered upright. If anything fails, returns the input image.
    static func upright(_ cg: CGImage, orientation: CGImagePropertyOrientation) -> CGImage {
        // Fast-path: already upright
        if orientation == .up { return cg }

        let srcW = cg.width
        let srcH = cg.height

        // For left/right orientations the canvas is transposed
        let transpose = (orientation == .left || orientation == .leftMirrored || orientation == .right || orientation == .rightMirrored)
        let dstW = transpose ? srcH : srcW
        let dstH = transpose ? srcW : srcH

        // Build a CGContext matching the source
        let colorSpace = cg.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = cg.bitmapInfo.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: dstW,
            height: dstH,
            bitsPerComponent: cg.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return cg
        }

        // Apply the correct transform so that drawing the source will yield an upright result
        switch orientation {
        case .up:
            break
        case .upMirrored:
            ctx.translateBy(x: CGFloat(dstW), y: 0)
            ctx.scaleBy(x: -1, y: 1)
        case .down:
            ctx.translateBy(x: CGFloat(dstW), y: CGFloat(dstH))
            ctx.rotate(by: .pi)
        case .downMirrored:
            ctx.translateBy(x: 0, y: CGFloat(dstH))
            ctx.scaleBy(x: 1, y: -1)
        case .left:
            ctx.translateBy(x: 0, y: CGFloat(dstH))
            ctx.rotate(by: -.pi / 2)
        case .leftMirrored:
            ctx.translateBy(x: CGFloat(dstW), y: CGFloat(dstH))
            ctx.scaleBy(x: -1, y: 1)
            ctx.rotate(by: -.pi / 2)
        case .right:
            ctx.translateBy(x: CGFloat(dstW), y: 0)
            ctx.rotate(by: .pi / 2)
        case .rightMirrored:
            ctx.scaleBy(x: -1, y: 1)
            ctx.translateBy(x: -CGFloat(dstW), y: 0)
            ctx.rotate(by: .pi / 2)
        @unknown default:
            break
        }

        // Draw the pixels into the new context
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: srcW, height: srcH))
        return ctx.makeImage() ?? cg
    }
}
