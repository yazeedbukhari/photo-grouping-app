# EmbeddingRepository

## Purpose
Local persistence for embeddings and metadata.
Acts as the persistence boundary between math logic and storage.

## Inputs / Outputs
- Input: Embedding
- Output: persisted EmbeddingRecord
- Projection: PhotoWithVec for grouping

## Structs
```
struct EmbeddingRecord: Identifiable {
    let id: UUID
    let photoID: PhotoID
    let dim: Int
    let modelVersion: ModelVersion
    let createdAt: EpochMillis
    let vector: Data
    let checksum: UInt32
}
```

## APIs
```
func upsert(_ e: Embedding) throws
func fetchVectorsWithTimes() throws -> [PhotoWithVec]
func fetchStale(current: ModelVersion) throws -> [PhotoID]
```

## Design Notes
- Keeps persistence details hidden from the rest of the system.
- Store vectors compressed (int8 or Data).
- modelVersion + createdAt = reproducibility + migration.
- Returns clean projections (PhotoWithVec) to avoid DB coupling.
- Handles migrations and staleness detection.
