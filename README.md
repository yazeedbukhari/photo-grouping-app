# Photo Grouping App
Automatically groups your photos by visual and temporal similarity — all on-device.

---

### 🧩 Problem
I have hundreds of clusters of similar photos. It takes up too much storage and is tedious to clean up manually.

### 💡 Solution
An iOS app that automatically groups your photos into clusters and suggests one or two to keep — all on-device, ensuring privacy and efficiency.

---

### ⚙️ Pipeline
User Photos  
→ **Preprocessing** (resize, normalize)  
→ **Embedding Generation** (Core ML model outputs vector per photo)  
→ **Storage** (SwiftData saves embedding + photo metadata)  
→ **Grouping** (clustering by vector similarity + capture time proximity)  
→ **Suggestion Engine** (ranks top photo per cluster by clarity/lighting)

#### Details:
- Tech Stack: Swift (only for iOS)
- Storage: Local SwiftData for embeddings & metadata
- No cloud uploads; all ML runs on-device
