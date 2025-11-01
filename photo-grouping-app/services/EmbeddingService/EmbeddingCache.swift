//
//  EmbeddingCache.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-31.
//

//  Purpose:
//    Avoid recomputing embeddings for the same (photoID, pixels, modelVersion).
//
//  Why these keys:
//    - modelVersion: embeddings are model-specific; mixing versions breaks distances.
//    - photoID: two different photos could downscale to the same pixel hash (rare, but possible).
//    - pixelHash: cheap "same pixels" fingerprint so edits bust cache.
//
//  Implementation notes:
//    - Simple in-memory dictionary guarded by a lock — tiny, fast, and fine for v1.
//    - When you add a disk-backed repository, leave this in place as a hot cache.
//

import Foundation

protocol EmbeddingCache: Sendable {
    /// Fetch a cached embedding if present.
    /// - Returns: Embedding or nil if not present.
    func get(modelVersion: ModelVersion, photoID: PhotoID, pixelHash: UInt64) -> Embedding?

    /// Insert/overwrite the cache entry for the embedding's keys.
    func put(_ emb: Embedding)
}

/// Minimal thread-safe in-memory cache.
/// We prefer a lock over an actor here to keep overhead low on hot paths.
/// (Actors are great too; pick your concurrency primitive and stay consistent.)
final class InMemoryEmbeddingCache: EmbeddingCache {
    private struct Key: Hashable {
        let modelVersion: ModelVersion
        let photoID: PhotoID
        let pixelHash: UInt64
    }

    private var dict: [Key: Embedding] = [:]
    private let lock = NSLock()

    func get(modelVersion: ModelVersion, photoID: PhotoID, pixelHash: UInt64) -> Embedding? {
        lock.lock(); defer { lock.unlock() }
        return dict[Key(modelVersion: modelVersion, photoID: photoID, pixelHash: pixelHash)]
    }

    func put(_ emb: Embedding) {
        // Only cache when we have a pixelHash; if nil, skip caching to avoid false hits.
        guard let h = emb.pixelHash else { return }
        lock.lock(); defer { lock.unlock() }
        let k = Key(modelVersion: emb.modelVersion, photoID: emb.photoID, pixelHash: h)
        dict[k] = emb
    }
}
