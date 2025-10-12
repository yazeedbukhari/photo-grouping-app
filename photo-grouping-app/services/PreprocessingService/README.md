# PreprocesingService

## Purpose
Converts raw photo pixels into model-ready tensors with consistent color and scale.

## Inputs / Outputs
- Input: (PhotoRef, CGImage)
- Output: PreprocessedImage

## Structs
```
struct PreprocessConfig {
    let targetSize: CGSize
    let colorSpace: ColorSpaceType // .sRGB, .displayP3
    let normalize: Bool
}

struct PreprocessedImage {
    let photoID: PhotoID
    let tensor: MLShapedArray<Float32>
    let width: Int
    let height: Int
}
```

## Design Notes
- Always reproject into sRGB for model consistency.
- Apply orientation fixes using EXIF data.
- Normalization ensures numeric consistency (model trained on [0,1] floats).
- Keep config explicit for test reproducibility.
- Returns tensors ready for Core ML.
