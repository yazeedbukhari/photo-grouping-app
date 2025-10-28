# EmbeddingService

## Purpose
Runs Core ML embedding model on preprocessed images to produce feature vectors.

## Inputs / Outputs
- Input: [PreprocessedImage]
- Output: [Embedding]

## Structs
```
struct Embedding {
    let photoID: PhotoID
    let vector: [Float]
    let modelVersion: ModelVersion
    let createdAt: EpochMillis
}
```

## Design Notes
- Batch inference (≈50 photos) for efficiency.
- Keep embeddings deterministic per model version.
- Store vector length and dtype explicitly.
- If model changes, mark embeddings stale (re-embed later).
- Measure p50/p95 latency; track CPU and energy impact.
