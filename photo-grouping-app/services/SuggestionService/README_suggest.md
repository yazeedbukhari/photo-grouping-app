# SuggestionService

## Purpose
Ranks photos within each group to recommend which to keep.

## Inputs / Outputs
- Input: [PhotoGroup] + [PhotoQuality]
- Output: [Suggestion]

## Structs
```
struct PhotoQuality {
    let photoID: PhotoID
    let sharpness: Float?
    let brightness: Float?
    let faceCount: Int?
    let distanceToCentroid: Float?
}

struct Suggestion {
    let groupID: GroupID
    let ranked: [PhotoID]
    let keepTop: Int
    let evidence: [String: Float]?
}
```

## Design Notes
- Combine heuristic + ML features.
- Normalize all features to [0,1].
- Use distanceToCentroid + sharpness as base ranking.
- Include evidence for transparency (“why this photo”).
- Keep pure logic — UI decides how to show results.
