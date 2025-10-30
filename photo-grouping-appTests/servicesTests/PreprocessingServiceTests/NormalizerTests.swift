//
//  NormalizerTests.swift
//  photo-grouping-appTests
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import XCTest
import CoreGraphics
@testable import photo_grouping_app

final class NormalizerTests: XCTestCase {

    // MARK: - Helpers
    private func makeContext(width: Int, height: Int, colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!) -> CGContext {
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            XCTFail("Failed to create CGContext")
            fatalError("Unreachable after XCTFail")
        }
        return ctx
    }

    private func approxEqual(_ a: Float, _ b: Float, tol: Float = 1.5) -> Bool { // 8-bit tolerance
        return abs(a - b) <= tol
    }

    // MARK: - Tests

    func testLengthAndRGBOrderWithoutNormalization() {
        // Make a 2x1 image: [Red, Green]
        let ctx = makeContext(width: 2, height: 1)
        ctx.setFillColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        ctx.setFillColor(CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
        let cg = ctx.makeImage()!

        let floats = Normalizer.toFloatsRGB(cg, normalize01: false)
        XCTAssertEqual(floats.count, 2 * 1 * 3)
        // Expect [255,0,0, 0,255,0]
        XCTAssertTrue(approxEqual(floats[0], 255)) // R0
        XCTAssertTrue(approxEqual(floats[1], 0))   // G0
        XCTAssertTrue(approxEqual(floats[2], 0))   // B0
        XCTAssertTrue(approxEqual(floats[3], 0))   // R1
        XCTAssertTrue(approxEqual(floats[4], 255)) // G1
        XCTAssertTrue(approxEqual(floats[5], 0))   // B1
    }

    func testNormalization01ScalesToUnitRange() {
        // 1x1 pure blue
        let ctx = makeContext(width: 1, height: 1)
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let cg = ctx.makeImage()!

        let floats = Normalizer.toFloatsRGB(cg, normalize01: true)
        XCTAssertEqual(floats.count, 3)
        XCTAssertTrue(abs(floats[0] - 0.0) <= 1e-4)
        XCTAssertTrue(abs(floats[1] - 0.0) <= 1e-4)
        XCTAssertTrue(abs(floats[2] - 1.0) <= 1e-3) // tolerate tiny rounding
    }

    func testPremultipliedAlphaEffectWhenDroppingAChannel() {
        // Semi-transparent pixel (alpha 0.5). In premultiplied RGBA8, stored RGB ≈ RGB * A.
        // Use color (10, 20, 30), A = 0.5 -> expected ~ (5, 10, 15) without normalization.
        let ctx = makeContext(width: 1, height: 1)
        let r: CGFloat = 10.0/255.0
        let g: CGFloat = 20.0/255.0
        let b: CGFloat = 30.0/255.0
        ctx.setFillColor(CGColor(srgbRed: r, green: g, blue: b, alpha: 0.5))
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let cg = ctx.makeImage()!

        let floats = Normalizer.toFloatsRGB(cg, normalize01: false)
        XCTAssertEqual(floats.count, 3)
        XCTAssertTrue(approxEqual(floats[0], 5, tol: 2))
        XCTAssertTrue(approxEqual(floats[1], 10, tol: 2))
        XCTAssertTrue(approxEqual(floats[2], 15, tol: 2))
    }
}
