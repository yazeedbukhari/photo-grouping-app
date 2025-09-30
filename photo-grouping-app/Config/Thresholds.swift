//
//  Thresholds.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-09-29.
//

import Foundation

struct Thresholds {
    var duplicateThreshold: Float = 0.95    // nearly exact picture
    var sceneThreshold: Float = 0.70        // slightly different angle but same scene
    var pHashHammingThreshold: Int = 8      // for comparing hashed (blurred) version of the image
    
    static var defualt: Thresholds {
        return Thresholds()
    }
}

// optinoal: make thresholds user-adjustable
