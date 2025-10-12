# PhotoAssetGateway

## Purpose
Handles all communication with the user’s Photos library. Fetches photo metadata and lazily loads pixel data for preprocessing. This is the entry point into the system.

## Inputs / Outputs
- Input: User’s gallery (PhotosKit PHAssets)
- Output: [PhotoRef] (light metadata structs)
- Optional: CGImage or CVPixelBuffer for pixel data

## Structs
```
struct PhotoRef {
    let photoID: PhotoID
    let captureTime: EpochMillis
    let dimensions: CGSize
    let orientation: CGImagePropertyOrientation
    let location: CLLocationCoordinate2D?
    let sourceType: PhotoSource // e.g., camera, screenshot
}
```

## APIs
```
func listNewPhotos(since: EpochMillis?) async throws -> [PhotoRef]
func loadPixels(for ref: PhotoRef) async throws -> CGImage
```

## Design Notes
- Only layer that touches PhotosKit.
- No model logic; pure data access.
- loadPixels deferred until needed (memory safety).
- Add a simple perceptual hash to skip reprocessing identical frames.
- All outputs immutable.
