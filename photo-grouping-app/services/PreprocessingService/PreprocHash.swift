//
//  PreprocHash.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-30.
//

import Foundation

struct PreprocHash: Hashable, Codable { let value: String }

extension PreprocHash {
    static func make(for cfg: PreprocessConfig) -> PreprocHash {
        .init(value: "w\(Int(cfg.targetSize.width))h\(Int(cfg.targetSize.height))_n\(cfg.normalize01 ? 1 : 0)")
    }
}
