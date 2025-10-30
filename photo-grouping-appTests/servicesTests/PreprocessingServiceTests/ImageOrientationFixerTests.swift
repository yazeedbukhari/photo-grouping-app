//
//  ImageOrientationFixerTests.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import XCTest
@testable import photo_grouping_app

final class ImageOrientationFixerTests: XCTestCase {
    private func makeTestImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            fatalError("Failed to create CGContext")
        }
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()!
    }
    
    func testLeftOrientationIsTransposed() {
        let cg = makeTestImage(width: 3, height: 2)
        let out = ImageOrientationFixer.upright(cg, orientation: .left)
        XCTAssertEqual(out.width, cg.height)
        XCTAssertEqual(out.height, cg.width)
    }
}
