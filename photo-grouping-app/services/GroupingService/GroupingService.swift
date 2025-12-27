//
//  GroupingService.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-12-27.
//
import Foundation

final class GroupingService {
    
    // assume photos is already sorted by capturetime
    func group(photos: [PhotoWithVec], config: GroupingConfig) -> [PhotoGroup] {
        let timeWindowMillis: Int64 = config.timeWindowMins * 60 * 1000
        
        guard !photos.isEmpty else { return [] }
        
        var groups: [PhotoGroup] = []
        
        var currentMemberIDs: [PhotoID] = []
        var currentStartTime: EpochMillis = 0
        var currentEndTime: EpochMillis = 0
        var currentCentroid: [Float] = []
        var currentCount: Int = 0
        
        func finalizeCurrentGroup() {
            guard currentCount > 0 else { return }
            guard currentCount >= config.minClusterSize else { return }

            // Deterministic ID
            let id = GroupID(
                firstPhotoID: currentMemberIDs[0],
                startTime: currentStartTime
            )

            groups.append(
                PhotoGroup(
                    groupID: id,
                    memberIDs: currentMemberIDs,
                    centroid: currentCentroid,
                    startTime: currentStartTime,
                    endTime: currentEndTime
                )
            )
        }
        
        
        for photo in photos {
            if currentCount == 0 {
                currentMemberIDs = [photo.photoID]
                currentCentroid = photo.vector
                currentStartTime = photo.captureTime
                currentEndTime = photo.captureTime
                currentCount = 1
                
                continue
            }
            
            let withinTimeWindow = (photo.captureTime - currentEndTime) <= timeWindowMillis
            let withinThreshold = dotSimilarity(v1: currentCentroid, v2: photo.vector) >= config.similarityThreshold
            
            if !(withinTimeWindow && withinThreshold) {
                finalizeCurrentGroup()
                
                currentMemberIDs = [photo.photoID]
                currentCentroid = photo.vector
                currentStartTime = photo.captureTime
                currentEndTime = photo.captureTime
                currentCount = 1
                
                continue
            }
            
            currentMemberIDs.append(photo.photoID)
            currentEndTime = photo.captureTime
            currentCount += 1
            
            let n = Float(currentCount)
            precondition(currentCentroid.count == photo.vector.count, "Embedding dimension mismatch")
            for i in currentCentroid.indices {
                currentCentroid[i] = currentCentroid[i] + (photo.vector[i] - currentCentroid[i]) / n
            }
            currentCentroid = normalizeL2(currentCentroid)
        }
        
        finalizeCurrentGroup()
        
        return groups
    }
}
