//
//  PreprocessConfig.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import CoreGraphics

struct PreprocessConfig: Equatable, Codable {
    let targetSize: CGSize     // 224x224 for ML models
    let normalize01: Bool      // true: [0,1], false: [0,255]
}
