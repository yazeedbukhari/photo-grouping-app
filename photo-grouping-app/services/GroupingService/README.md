# GroupingService

## Purpose
Clusters embeddings into visual + temporal groups.

## Inputs / Outputs
- Input: [PhotoWithVec]
- Output: [PhotoGroup]

##Structs
```
struct GroupingConfig {
    let similarityThreshold: Float
    let timeWindowSecs: Int
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
    let timeRange: ClosedRange<EpochMillis>
}
```

## Design Notes
- Deterministic: sort by PhotoID before clustering.
- Use time windows to prune comparisons (sub-quadratic).
- randomSeed gives reproducibility in tests.
- Generate GroupID as a hash of sorted members + modelVersion.
- Output is pure value data (no side effects).
- Future: add approximate NN index for larger libraries.
