//
//  EmbeddingService.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-31.
//

//  Purpose:
//    Public façade: turn ONE preprocessed image into an `Embedding` that matches your spec.
//
//  Responsibilities here:
//    1) Compute a **stable pixel hash** (fast downscale + simple mixer).
//       - Why: cheap cache key; invalidates if pixels change.
//    2) Consult the in-memory cache by (modelVersion, photoID, pixelHash).
//       - Why: avoid repeated Vision work.
//    3) Call FeaturePrintEmbedder to get a **unit-length** vector.
//    4) Wrap into your `Embedding` struct, filling `vectorCount`, `dtype`, `createdAt`.
//    5) Store into cache.
//
//  Non-responsibilities (kept out on purpose):
//    - Batching / concurrency control (you asked to keep 1-at-a-time).
//    - Disk persistence (belongs to EmbeddingRepository).
//    - Clustering or any downstream math.
//

import Foundation
import CoreGraphics

final class EmbeddingService {
    // Dependencies:
    private let embedder: FeaturePrintEmbedder
    private let cache: EmbeddingCache

    // Versioning is part of your core identity model. Keep it explicit.
    private let modelVersion: ModelVersion

    /// Designated initializer. We default to FeaturePrint v1 and in-memory cache.
    init(modelVersion: ModelVersion = ModelVersion("featureprint_v1"),
         cache: EmbeddingCache = InMemoryEmbeddingCache()) {
        self.modelVersion = modelVersion
        self.embedder = FeaturePrintEmbedder()
        self.cache = cache
    }

    /// Convert a single CGImage into an Embedding, respecting cache + version.
    /// - Parameters:
    ///   - photoID: stable domain ID of the photo (from PhotosKit localIdentifier)
    ///   - cgImage: preprocessed (sRGB, upright) pixels
    /// - Returns: Embedding that conforms to `EmbeddingTypes.swift`
    func embed(photoID: PhotoID, cgImage: CGImage) throws -> Embedding {
        // 1) Build a fast pixel hash (downscale + simple FNV-1a style mixer).
        //    - Why downscale: hashing fewer bytes is faster and stable enough for cache keys.
        let pxHash = Self.quickPixelHash(cgImage)

        // 2) Cache lookup keyed by (modelVersion, photoID, pixelHash).
        if let cached = cache.get(modelVersion: modelVersion, photoID: photoID, pixelHash: pxHash) {
            return cached
        }

        // 3) Compute the vector with Vision (unit-length by contract).
        let vec = try embedder.embed(cgImage)

        // 4) Wrap into your Embedding type. We fill required metadata explicitly.
        let emb = Embedding(
            photoID: photoID,
            vector: vec,
            vectorCount: vec.count,     // explicitly store length to lock schema
            dtype: .float32,            // FeaturePrint emits 32-bit floats
            modelVersion: modelVersion, // critical for cache/re-embed semantics
            createdAt: Self.nowMillis(),
            pixelHash: pxHash           // helps debugging and cache auditing
        )

        // 5) Save into the cache for future identical calls.
        cache.put(emb)

        return emb
    }

    // MARK: - Utilities

    /// Milliseconds since epoch as Int64 (matches your `EpochMillis` alias).
    private static func nowMillis() -> EpochMillis {
        EpochMillis(Date().timeIntervalSince1970 * 1000.0)
    }

    /// Cheap, stable pixel hash:
    /// - Draw to a tiny 32x32 sRGB RGBA8 buffer.
    /// - Mix bytes with a 64-bit FNV-1a style hash.
    /// This is *not* cryptographic — just good enough to detect "same pixels" for caching.
    private static func quickPixelHash(_ cg: CGImage) -> UInt64 {
        let thumbW = min(32, cg.width)
        let thumbH = min(32, cg.height)

        // Create a tiny bitmap context (sRGB, RGBA8, premultiplied last).
        guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                data: nil,
                width: thumbW, height: thumbH,
                bitsPerComponent: 8,
                bytesPerRow: thumbW * 4,
                space: cs,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            // Fallback (very rare): combine dims into a stable number.
            return UInt64(cg.width &* 31 &+ cg.height &* 131)
        }

        // Draw scaled image into the tiny canvas.
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: thumbW, height: thumbH))

        guard let data = ctx.data else {
            return UInt64(cg.width &* 31 &+ cg.height &* 131)
        }

        // FNV-1a 64-bit
        var h: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x00000100000001B3
        let count = thumbW * thumbH * 4
        let ptr = data.bindMemory(to: UInt8.self, capacity: count)
        for i in 0..<count {
            h ^= UInt64(ptr[i])
            h = h &* prime
        }
        return h
    }
}
