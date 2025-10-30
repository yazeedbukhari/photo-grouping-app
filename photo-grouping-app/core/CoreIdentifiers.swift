//
//  CoreIdentifiers.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-12.
//

import Foundation

// MARK: - Core Domain Identifiers

/// Unique identifier for a photo asset.
/// Wraps the PhotosKit localIdentifier (String) for type safety.
struct PhotoID: Hashable, Codable {
    let raw: String
    init(_ raw: String) { self.raw = raw }
}

/// Unique identifier for a generated photo group.
/// Deterministic hash of member IDs + model version.
struct GroupID: Hashable, Codable {
    let raw: String
    init(_ raw: String) { self.raw = raw }
}

/// Model version string for embeddings (e.g., "EmbedModel_v3.1").
struct ModelVersion: Hashable, Codable {
    let raw: String
    init(_ raw: String) { self.raw = raw }
}

/// Timestamp in milliseconds since epoch.
/// Using Int64 avoids floating-point rounding and serializes cleanly.
typealias EpochMillis = Int64
