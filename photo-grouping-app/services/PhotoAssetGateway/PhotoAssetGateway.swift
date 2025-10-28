//
//  PhotoAssetGateway.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-26.
//

import Photos
import UIKit

protocol PhotoAssetGateway {
    func listRecent(limit: Int) -> [PhotoRef]          // metadata only
    func fetchImage(for id: PhotoID, target: CGSize) async throws -> UIImage
}

final class PhotosKitGateway: PhotoAssetGateway {
    private let lookup = AssetLookup()
    private let cache = PixelCache()

    init() {
        let results = PHAsset.fetchAssets(with: .image, options: {
            let o = PHFetchOptions()
            o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            return o
        }())
        lookup.warm(from: results)
    }

    func listRecent(limit: Int) -> [PhotoRef] {
        let results = PHAsset.fetchAssets(with: .image, options: {
            let o = PHFetchOptions()
            o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            o.fetchLimit = limit
            return o
        }())
        var out: [PhotoRef] = []
        results.enumerateObjects { a, _, stop in
            out.append(.init(id: .init(raw: a.localIdentifier),
                             creationDate: a.creationDate,
                             isFavorite: a.isFavorite))
            if out.count >= limit { stop.pointee = true }
        }
        return out
    }

    enum FetchErr: Error { case missingAsset }

    func fetchImage(for id: PhotoID, target: CGSize) async throws -> UIImage {
        if let hit = await cache.get(id) { return hit }
        guard let asset = lookup.asset(for: id) else { throw FetchErr.missingAsset }

        return try await withCheckedThrowingContinuation { cont in
            let opts = PHImageRequestOptions()
            opts.deliveryMode = .highQualityFormat
            opts.isNetworkAccessAllowed = true   // iCloud originals
            opts.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: target,
                contentMode: .aspectFill,
                options: opts
            ) { image, info in
                if let img = image {
                    Task { await self.cache.set(id, img: img) }
                    cont.resume(returning: img)
                } else {
                    cont.resume(throwing: FetchErr.missingAsset)
                }
            }
        }
    }
}
