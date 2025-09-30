//
//  AssetEmbedding.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-09-27.
//

// Stores embedding vector, pHash, model version, etc. per photo

import Foundation
import SwiftData

@Model
class AssetEmbedding {
    @Attribute(.unique) var photoID: String     // will be PHAsset.localIdentifier
    var modelVersion: String
    var preprocHash: String
    var embedding: [Float]                      // of size EmbedConfig.embeddingDimension
    var pHash: String
    var createdAt: Date
    var updatedAt: Date
    
    init(photoID: String, modelVersion: String, preprocHash: String, embedding: [Float], pHash: String) {
        self.photoID = photoID
        self.modelVersion = modelVersion
        self.preprocHash = preprocHash
        self.embedding = embedding
        self.pHash = pHash
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
