//
//  ImageResizer.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import CoreGraphics
import Accelerate

/// Resizes an image to the desired size while converting to sRGB RGBA8.
enum ImageResizer {
    /// Resize to `dstSize` using vImage Lanczos, returning **RGBA8888 premultiplied** in sRGB.
    /// Assumes input is (or has been interpreted as) sRGB. If your source has exotic profiles,
    /// run a ColorSync transform or draw-into-sRGB once before calling this.
    static func resizeToSRGBA(_ srcCG: CGImage, to dstSize: CGSize) -> CGImage? {
        let dstW = max(1, Int(dstSize.width.rounded()))
        let dstH = max(1, Int(dstSize.height.rounded()))

        // 1) Describe the desired bitmap for the final CGImage (RGBA8888 premultiplied-last).
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: alphaInfo.rawValue))

        // 2) Initialize a vImage buffer from the source CGImage.
        //    We’ll request **ARGB8888 premultiplied-first** because that’s vImage’s fast lane.
        var srcBuffer = vImage_Buffer()
        var srcFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(colorSpace),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)), // ARGB8888
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        var err = vImageBuffer_InitWithCGImage(
            &srcBuffer,
            &srcFormat,
            nil,
            srcCG,
            vImage_Flags(kvImageNoFlags)
        )
        guard err == kvImageNoError else { return nil }

        // 3) Allocate the destination buffer in ARGB8888 (vImage’s native op format).
        var dstBuffer = vImage_Buffer()
        err = vImageBuffer_Init(
            &dstBuffer,
            vImagePixelCount(dstH),
            vImagePixelCount(dstW),
            32, // bits per pixel for ARGB8888
            vImage_Flags(kvImageNoFlags)
        )
        guard err == kvImageNoError else {
            free(srcBuffer.data)
            return nil
        }

        // 4) Perform the scale using Lanczos3. High-quality for downscales.
        err = vImageScale_ARGB8888(
            &srcBuffer,
            &dstBuffer,
            nil,
            vImage_Flags(kvImageHighQualityResampling) // enables Lanczos3 for scale
        )
        free(srcBuffer.data)
        guard err == kvImageNoError else {
            free(dstBuffer.data)
            return nil
        }

        // 5) If your downstream expects **RGBA**, permute channels ARGB -> RGBA.
        //    Map indices: A(0), R(1), G(2), B(3) → R(1), G(2), B(3), A(0)
        var rgbaBuffer = vImage_Buffer()
        err = vImageBuffer_Init(
            &rgbaBuffer,
            vImagePixelCount(dstH),
            vImagePixelCount(dstW),
            32,
            vImage_Flags(kvImageNoFlags)
        )
        guard err == kvImageNoError else {
            free(dstBuffer.data)
            return nil
        }

        let permuteMap: [UInt8] = [1, 2, 3, 0]
        err = vImagePermuteChannels_ARGB8888(&dstBuffer, &rgbaBuffer, permuteMap, vImage_Flags(kvImageNoFlags))
        free(dstBuffer.data)
        guard err == kvImageNoError else {
            free(rgbaBuffer.data)
            return nil
        }

        // 6) Materialize a CGImage from the RGBA buffer with sRGB + premultipliedLast.
        var rgbaFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(colorSpace),
            bitmapInfo: bitmapInfo,
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        guard let outCG = vImageCreateCGImageFromBuffer(
            &rgbaBuffer,
            &rgbaFormat,
            { userData, bufData in
                // Custom free callback for the internal pixels.
                if let data = bufData { free(UnsafeMutableRawPointer(mutating: data)) }
            },
            nil,
            vImage_Flags(kvImageNoAllocate),
            &err
        )?.takeRetainedValue(), err == kvImageNoError else {
            free(rgbaBuffer.data)
            return nil
        }

        return outCG
    }
}
