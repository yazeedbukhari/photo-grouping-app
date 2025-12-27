//
//  GroupingTypes.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-12-27.
//

struct GroupingConfig {
    let similarityThreshold: Float
    let timeWindowMins: Int64
    let minClusterSize: Int
    let randomSeed: UInt64?
}

struct PhotoWithVec {
    let photoID: PhotoID
    let captureTime: EpochMillis
    let vector: [Float]
}

struct PhotoGroup {
    let groupID: GroupID
    let memberIDs: [PhotoID]
    let centroid: [Float]
    let startTime: EpochMillis
    let endTime: EpochMillis
}
