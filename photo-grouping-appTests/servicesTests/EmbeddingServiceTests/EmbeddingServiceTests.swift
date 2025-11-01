//
//  EmbeddingServiceTests.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-31.
//

//  Purpose: Thin tests to validate invariants (unit norm, determinism, caching works).
//  Why: If Apple changes FeaturePrint behavior (or we break preprocessing), we’ll notice.

import XCTest
import CoreGraphics
@testable import photo_grouping_app

final class EmbeddingServiceTests: XCTestCase {
    func testUnitLengthAndDeterminism() throws {
        let svc = EmbeddingService()
        
        // Build two tiny CGImages in-memory (solid colors) to avoid fixtures.
        let red = try Self.makeSolidCGImage(width: 32, height: 32, rgba: (255, 0, 0, 255))
        let red2 = try Self.makeSolidCGImage(width: 32, height: 32, rgba: (255, 0, 0, 255))
        let blue = try Self.makeSolidCGImage(width: 32, height: 32, rgba: (0, 0, 255, 255))
        
        let e1 = try svc.embed(cgImage: red)
        let e2 = try svc.embed(cgImage: red2)
        let e3 = try svc.embed(cgImage: blue)
        
        // 1) Unit length within tolerance
        XCTAssertTrue(abs(Self.l2(e1.values) - 1.0) < 1e-3, "Embedding should be L2 ~ 1")
        
        // 2) Deterministic for identical pixels
        XCTAssertEqual(e1.values.count, e2.values.count)
        XCTAssertLessThan(Self.cosineDistance(e1.values, e2.values), 1e-4, "Red vs Red2 should be near-identical")
        
        // 3) Different colors should not be identical (they may still be visually 'related')
        XCTAssertGreaterThan(Self.cosineDistance(e1.values, e3.values), 1e-3, "Red vs Blue should differ")
        
        // 4) Cache sanity: second call should hit cache (can’t observe directly; but call twice)
        let _ = try svc.embed(cgImage: red) // if cache broken, timing would regress; here we just ensure no crash
    }
}

private extension EmbeddingServiceTests {
    static func l2(_ x: [Float]) -> Float {
        var s: Float = 0; for v in x { s += v*v }; return sqrt(s)
    }
    static func cosineDistance(_ a: [Float], _ b: [Float]) -> Float {
        precondition(a.count == b.count)
        var dot: Float = 0
        var s1: Float = 0
        var s2: Float = 0
        for i in 0..<a.count { dot += a[i]*b[i]; s1 += a[i]*a[i]; s2 += b[i]*b[i] }
        let n = (sqrt(s1)*sqrt(s2))
        if n == 0 { return 1 } // degenerate
        let cosSim = dot / n
        return 1 - cosSim
    }
    
    static func makeSolidCGImage(width: Int, height: Int, rgba: (UInt8, UInt8, UInt8, UInt8)) throws -> CGImage {
        // Create an sRGB RGBA8 bitmap and fill it with a solid color.
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bytesPerRow = width * 4
        guard let ctx = CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw NSError(domain: "Test", code: -1) }
        
        // Fill manually for determinism.
        guard let data = ctx.data else { throw NSError(domain: "Test", code: -2) }
        let ptr = data.bindMemory(to: UInt8.self, capacity: width*height*4)
        for i in 0..<(width*height) {
            ptr[i*4 + 0] = rgba.0 // R
            ptr[i*4 + 1] = rgba.1 // G
            ptr[i*4 + 2] = rgba.2 // B
            ptr[i*4 + 3] = rgba.3 // A
        }
        return ctx.makeImage()!
    }
}
