//
//  ImageQuality.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import CoreGraphics
import Accelerate
import UIKit

/// Simple technical metrics describing photo quality.
struct Quality {
    let sharpness: Double      // Higher = crisper focus
    let meanBrightness: Double // 0...1 normalized brightness
    let exposureOK: Bool       // Brightness within [lo, hi]
}

enum QualityFeatures {
    // Sharpness via Laplacian variance
    static func sharpnessLaplacian(_ cg: CGImage) -> Double {
        var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                          bitsPerPixel: 8,
                                          colorSpace: nil,
                                          bitmapInfo: CGBitmapInfo(),
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: .defaultIntent)

        var src = vImage_Buffer()
        defer { free(src.data) }
        vImageBuffer_InitWithCGImage(&src, &format, nil, cg, vImage_Flags(kvImageNoFlags))

        var dest = vImage_Buffer()
        vImageBuffer_Init(&dest, src.height, src.width, 8, vImage_Flags(kvImageNoFlags))
        defer { free(dest.data) }

        let kernel: [Int16] = [0,1,0,1,-4,1,0,1,0]
        vImageConvolve_Planar8(&src, &dest, nil, 0, 0,
                               kernel, 3, 3, 1, 0,
                               vImage_Flags(kvImageEdgeExtend))
        
        // After vImageConvolve_Planar8 -> dest (planar 8-bit)
        let count = Int(dest.width * dest.height)
        let u8 = dest.data!.assumingMemoryBound(to: UInt8.self)

        // Convert to Float
        var f = [Float](repeating: 0, count: count)
        vDSP_vfltu8(u8, 1, &f, 1, vDSP_Length(count))

        // Variance via vDSP: Var(X) = E[X^2] - (E[X])^2
        var mean: Float = 0
        vDSP_meanv(f, 1, &mean, vDSP_Length(count))
        var meanSquare: Float = 0
        vDSP_measqv(f, 1, &meanSquare, vDSP_Length(count))
        let variance = Double(max(0, meanSquare - mean * mean))
        return variance
    }

    // Brightness and exposure test
    static func brightness(_ cg: CGImage) -> Double {
        let context = CGContext(data: nil,
                                width: cg.width,
                                height: cg.height,
                                bitsPerComponent: 8,
                                bytesPerRow: cg.width * 4,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.draw(cg, in: CGRect(x: 0, y: 0,
                                    width: cg.width,
                                    height: cg.height))
        guard let ptr = context.data else { return 0 }
        let pixels = ptr.bindMemory(to: UInt8.self, capacity: cg.width * cg.height * 4)

        var total: Double = 0
        for i in stride(from: 0, to: cg.width * cg.height * 4, by: 4) {
            let r = Double(pixels[i])
            let g = Double(pixels[i+1])
            let b = Double(pixels[i+2])
            total += (r + g + b) / 3.0
        }
        let avg = total / Double(cg.width * cg.height) / 255.0
        return avg
    }

    static func isExposureOK(_ brightness: Double,
                             lo: Double = 0.2,
                             hi: Double = 0.8) -> Bool {
        brightness >= lo && brightness <= hi
    }

    // Full extractor
    static func compute(for cg: CGImage) -> Quality {
        let s = sharpnessLaplacian(cg)
        let b = brightness(cg)
        let ok = isExposureOK(b)
        return Quality(sharpness: s, meanBrightness: b, exposureOK: ok)
    }
}
