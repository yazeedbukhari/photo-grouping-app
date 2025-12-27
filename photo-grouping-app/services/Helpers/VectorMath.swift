//
//  VectorMath.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-12-27.
//

import Foundation

/// Returns an L2-normalized copy of `x`.
/// If the vector has zero magnitude, returns it unchanged.
internal func normalizeL2(_ x: [Float]) -> [Float] {
    var sum: Float = 0
    for v in x { sum += v * v }

    let norm = sqrt(sum)
    guard norm > 0 else { return x }

    let inv: Float = 1.0 / norm
    return x.map { $0 * inv }
}

/// Returns dot similarity in [-1, 1].
/// Requires both vectors to be L2-normalized and of equal length.
internal func dotSimilarity(v1: [Float], v2: [Float]) -> Float {
    precondition(v1.count == v2.count, "Vector length mismatch")

    var dot: Float = 0
    for i in 0..<v1.count {
        dot += v1[i] * v2[i]
    }

    return dot
}
