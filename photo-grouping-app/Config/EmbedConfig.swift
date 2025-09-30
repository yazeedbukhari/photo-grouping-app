//
//  EmbedConfigs.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-09-27.
//

import Foundation

struct EmbedConfig {
    static let modelVersion = "embed-v0.0.0"    // update every change
    static let preprocHash = "preproc-v000"     // update every change
    static let inputImageSize = 224
    static let embeddingDimension = 128
    
    static func needsRecompute(storedVersion: String, storedHash: String) -> Bool {
            return storedVersion != modelVersion || storedHash != preprocHash
    }
}
