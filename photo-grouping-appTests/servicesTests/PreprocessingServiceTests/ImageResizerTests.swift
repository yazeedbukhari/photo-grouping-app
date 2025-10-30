//
//  ImageResizerTests.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import XCTest
import CoreGraphics
import Accelerate
@testable import photo_grouping_app

final class ImageResizerTests: XCTestCase {
    // MARK: - Helpers
    private func makeSolidCGImage(width: Int, height: Int, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        // RGBA8888 premultiplied-last, byteOrder32Big to match ImageResizer output contract
        let bitmapInfo: CGBitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)]
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { fatalError("Failed to create CGContext for test image") }

        ctx.setFillColor(red: r, green: g, blue: b, alpha: a)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let cg = ctx.makeImage() else { fatalError("Failed to make CGImage from context") }
        return cg
    }

    private func getPixelRGBA(_ cg: CGImage, x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        guard let provider = cg.dataProvider, let data = provider.data else { fatalError("No data provider on CGImage") }
        let ptr = CFDataGetBytePtr(data)!
        let bpr = cg.bytesPerRow
        let offset = y * bpr + x * 4
        let big = cg.bitmapInfo.contains(.byteOrder32Big)
        let little = cg.bitmapInfo.contains(.byteOrder32Little)
        // If CoreGraphics doesn’t specify, default to big-endian style byte order for RGBA reads
        let isLittle = little
        if isLittle {
            // Little-endian RGBA8888: memory order A, B, G, R
            let r = ptr[offset + 3]
            let g = ptr[offset + 2]
            let b = ptr[offset + 1]
            let a = ptr[offset + 0]
            return (r, g, b, a)
        } else {
            // Big-endian RGBA8888: memory order R, G, B, A
            let r = ptr[offset + 0]
            let g = ptr[offset + 1]
            let b = ptr[offset + 2]
            let a = ptr[offset + 3]
            return (r, g, b, a)
        }
    }

    // MARK: - Tests
    func testResize_OutputHasExpectedSizeAndFormat() {
        // Given a 19x13 semi-transparent red square in sRGB
        let src = makeSolidCGImage(width: 19, height: 13, r: 1.0, g: 0.0, b: 0.0, a: 0.5)
        let target = CGSize(width: 32, height: 24)

        // When
        guard let out = ImageResizer.resizeToSRGBA(src, to: target) else {
            XCTFail("resizeToSRGBA returned nil")
            return
        }

        // Then: geometry
        XCTAssertEqual(out.width, Int(target.width))
        XCTAssertEqual(out.height, Int(target.height))

        // Then: format
        XCTAssertEqual(out.bitsPerComponent, 8)
        if let csName = out.colorSpace?.name as String? {
            XCTAssertEqual(csName, CGColorSpace.sRGB as String)
        } else {
            XCTFail("Output image missing sRGB color space")
        }
        XCTAssertEqual(out.alphaInfo, .premultipliedLast, "Expected premultipliedLast alpha")
        // Note: CoreGraphics may omit explicit byte-order flags; we infer endianness via system default in pixel reads.
        // Sanity check bits-per-pixel implies 4 bytes per pixel
        XCTAssertEqual(out.bitsPerPixel, 32)
        // Note: pixel reading infers little-endian by system default when unspecified.
    }

    func testResize_UniformColorSurvivesAndIsPremultiplied() {
        // Given: 17x17 50% alpha pure red
        let src = makeSolidCGImage(width: 17, height: 17, r: 1.0, g: 0.0, b: 0.0, a: 0.5)
        let target = CGSize(width: 21, height: 21)

        guard let out = ImageResizer.resizeToSRGBA(src, to: target) else {
            XCTFail("resizeToSRGBA returned nil for uniform color test")
            return
        }

        // Sample center pixel
        let cx = out.width / 2
        let cy = out.height / 2
        let px = getPixelRGBA(out, x: cx, y: cy)

        // Expected premultiplied RGBA for 50% red: R≈128, G≈0, B≈0, A≈128
        // Allow a small tolerance for rounding
        let tol: Int = 3
        XCTAssert(abs(Int(px.r) - 128) <= tol, "R not premultiplied as expected: \(px.r)")
        XCTAssert(px.g <= px.r / 64 + 1, "G should be ~0: \(px.g)")
        XCTAssert(px.b <= px.r / 64 + 1, "B should be ~0: \(px.b)")
        XCTAssert(abs(Int(px.a) - 128) <= tol, "A not ~128: \(px.a)")
    }

    func testResize_ChannelOrderIsRGBA() {
        // Given: pure blue with 75% alpha
        let src = makeSolidCGImage(width: 9, height: 9, r: 0.0, g: 0.0, b: 1.0, a: 0.75)
        let target = CGSize(width: 15, height: 15)
        guard let out = ImageResizer.resizeToSRGBA(src, to: target) else {
            XCTFail("resizeToSRGBA returned nil for channel order test")
            return
        }

        let px = getPixelRGBA(out, x: out.width / 2, y: out.height / 2)
        // For RGBA premultiplied-last: R≈0, G≈0, B≈191, A≈191
        let tol: Int = 3
        XCTAssert(Int(px.r) <= tol, "R should be ~0 but was \(px.r)")
        XCTAssert(Int(px.g) <= tol, "G should be ~0 but was \(px.g)")
        XCTAssert(abs(Int(px.b) - 191) <= tol, "B should be ~191 but was \(px.b)")
        XCTAssert(abs(Int(px.a) - 191) <= tol, "A should be ~191 but was \(px.a)")
    }
}
