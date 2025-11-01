//
//  FeaturePrintEmbedder.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-31.
//

//
//  FeaturePrintEmbedder.swift
//  photo-grouping-app
//
//  Purpose:
//    A tiny adapter around Apple's Vision "FeaturePrint" to produce a
//    **unit-length** Float vector from a CGImage.
//
//  Why this file exists:
//    - We keep all Vision-specific code in one place so the rest of the app
//      doesn't import Vision or think in VN* types.
//    - Swapping to CLIP or another model later means changing just this file
//      and the model version constant, not the whole pipeline.
//
//  Contract with callers (important!):
//    - Input CGImage should already be sRGB and upright (orientation fixed).
//      Your PreprocessingService is responsible for that.
//    - Output is **L2-normalized** so downstream can use dot-product for cosine.
//
//  Notes on Vision API:
//    - VNGenerateImageFeaturePrintRequest yields VNFeaturePrintObservation.
//    - We copy raw floats from the observation's `data` buffer and normalize.
//

import Foundation
import Vision
import CoreImage
import CoreGraphics

struct FeaturePrintEmbedder {
    /// Convert a CGImage into a unit-length embedding using Vision FeaturePrint.
    /// - Parameter cg: preprocessed (sRGB, upright) CGImage
    /// - Returns: L2-normalized Float vector
    func embed(_ cg: CGImage) throws -> [Float] {
        // Build a CIImage (convenient for future Core Image tweaks, if any).
        let ci = CIImage(cgImage: cg)

        // Create the request object; no completion handler since we call synchronously.
        let request = VNGenerateImageFeaturePrintRequest(completionHandler: nil)

        // Create a handler. Orientation is assumed already corrected upstream.
        let handler = VNImageRequestHandler(ciImage: ci, options: [:])

        do {
            // Perform the Vision request on the current thread.
            // Call this from a background queue if you’re in app code.
            try handler.perform([request])
        } catch {
            // We surface a typed error in the service; here we throw raw and let the caller wrap.
            throw error
        }

        // Extract the feature print.
        guard let obs = request.results?.first as? VNFeaturePrintObservation else {
            // No vector came back — treat as an empty buffer error.
            throw EmbeddingError.emptyFeatureBuffer
        }

        // Copy out the raw float elements.
        let raw = try obs.toFloatArray()

        // Normalize to unit length so cosine distance = 1 - dot(a,b).
        let norm = l2Normalize(raw)
        return norm
    }

    // MARK: - Helpers

    /// L2-normalize a float vector. Keeps zeros as-is to avoid division by zero.
    private func l2Normalize(_ x: [Float]) -> [Float] {
        var sum: Float = 0
        for v in x { sum += v * v }
        let n = sqrt(sum)
        guard n > 0 else { return x }
        let inv = 1.0 / n
        // Map with multiplication is fast enough here; you can SIMD later if needed.
        return x.map { $0 * Float(inv) }
    }
}

// MARK: - VNFeaturePrintObservation bridging

private extension VNFeaturePrintObservation {
    /// Copies the underlying feature print bytes into a `[Float]`.
    /// This uses the documented `data` buffer + `elementCount`.
    func toFloatArray() throws -> [Float] {
        // Number of float elements expected.
        let count = Int(self.elementCount)

        // The feature data is delivered as raw bytes. We copy into Swift storage.
        let d = self.data
        // Sanity: size should match elementCount * sizeof(Float).
        let expectedBytes = count * MemoryLayout<Float>.stride
        guard d.count == expectedBytes else {
            // If Apple changes internal layout, this guard will catch it early.
            throw EmbeddingError.emptyFeatureBuffer
        }

        // Allocate output buffer of exactly `count` floats.
        var out = [Float](repeating: 0, count: count)
        // Copy bytes into our array storage.
        _ = out.withUnsafeMutableBytes { dst in
            d.withUnsafeBytes { src in
                memcpy(dst.baseAddress!, src.baseAddress!, expectedBytes)
            }
        }
        return out
    }
}
