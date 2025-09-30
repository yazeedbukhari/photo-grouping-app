//
//  GroupMember.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-09-29.
//

// to map groups to images as it could be a many to many relationship
import Foundation
import SwiftData

@Model
class GroupMember {
    var groupID: UUID
    var photoID: String
    
    init(groupID: UUID, photoID: String) {
        self.groupID = groupID
        self.photoID = photoID
    }
}
