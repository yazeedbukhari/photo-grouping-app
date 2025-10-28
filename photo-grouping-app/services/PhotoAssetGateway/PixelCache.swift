//
//  PixelCache.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-26.
//

import CoreGraphics
import UIKit

actor PixelCache {
    private let cache = NSCache<NSString, UIImage>()
    func get(_ id: PhotoID) -> UIImage? { cache.object(forKey: id.raw as NSString) }
    func set(_ id: PhotoID, img: UIImage) { cache.setObject(img, forKey: id.raw as NSString) }
}
