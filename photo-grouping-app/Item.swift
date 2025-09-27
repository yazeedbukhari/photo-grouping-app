//
//  Item.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-09-27.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
