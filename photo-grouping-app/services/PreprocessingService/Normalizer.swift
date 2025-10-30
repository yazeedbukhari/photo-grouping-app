//
//  Normalizer.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import CoreGraphics

enum Normalizer {
    static func toFloatsRGB(_ cg: CGImage, normalize01: Bool) -> [Float] {
        let width = cg.width
        let height = cg.height
        let count = width * height * 4 // RGBA

        let bytesPerRow = width * 4
        var raw = [UInt8](repeating: 0, count: count)

        // Force RGBA8 premultiplied-last
        guard let ctx = CGContext(
            data: &raw,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Convert to Float RGB only (drop alpha)
        var floats = [Float](repeating: 0, count: width * height * 3)

        for i in 0..<width*height {
            let r = raw[i*4 + 0]
            let g = raw[i*4 + 1]
            let b = raw[i*4 + 2]

            if normalize01 {
                floats[i*3 + 0] = Float(r) / 255.0
                floats[i*3 + 1] = Float(g) / 255.0
                floats[i*3 + 2] = Float(b) / 255.0
            } else {
                floats[i*3 + 0] = Float(r)
                floats[i*3 + 1] = Float(g)
                floats[i*3 + 2] = Float(b)
            }
        }

        return floats
    }
}
