//
//  PreprocessedImage.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

/// Holds pixel data that has been preprocessed and normalized, ready for ML embedding.
struct PreprocessedImage {
    let photoID: PhotoID
    let width: Int
    let height: Int
    let pixelsRGB: [Float]   // H*W*3, row-major, normalized as per config
    let preprocHash: PreprocHash
}
