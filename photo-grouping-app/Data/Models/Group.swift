//
//  Group.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-09-29.
//

import Foundation
import SwiftData

@Model
class Group {
    @Attribute(.unique) var groupID: UUID
    var startTime: Date     // datetime of first pic in group
    var endTime: Date       // datetime of last pic in group
    var representativePhotoID: String   // "best" picture
    var photoCount: Int
    var creationDate: Date
    
    init(groupID: UUID, startTime: Date, endTime: Date, representativePhotoID: String, photoCount: Int, creationDate: Date) {
        self.groupID = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.representativePhotoID = representativePhotoID
        self.photoCount = photoCount
        self.creationDate = Date()
    }
}
