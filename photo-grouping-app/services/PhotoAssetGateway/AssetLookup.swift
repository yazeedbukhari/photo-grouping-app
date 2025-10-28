//
//  AssetLookup.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-26.
//

import Photos

final class AssetLookup {
    private var map: [String: PHAsset] = [:]
    
    func warm(from result: PHFetchResult<PHAsset>) {
        result.enumerateObjects { asset, _, _ in
            self.map[asset.localIdentifier] = asset
        }
    }
    
    func asset(for id: PhotoID) -> PHAsset? {
        map[id.raw]
    }
}
