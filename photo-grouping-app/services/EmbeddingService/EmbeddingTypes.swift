//
//  EmbeddingTypes.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-31.
//

// EmbeddingTypes.swift

import Foundation

public enum DType: String, Sendable { case float32 }

struct Embedding: Sendable, Equatable {
    let photoID: PhotoID
    let vector: [Float]
    let vectorCount: Int
    let dtype: DType
    let modelVersion: ModelVersion
    let createdAt: EpochMillis
    let pixelHash: UInt64?
}

/// Errors surfaced by EmbeddingService. Keeping them narrow makes call sites easier to read.
public enum EmbeddingError: Error {
    case cannotCreateCIImage
    case visionFailed(underlying: Error?)
    case emptyFeatureBuffer
    case normalizationFailed
    case invalidInput
}
