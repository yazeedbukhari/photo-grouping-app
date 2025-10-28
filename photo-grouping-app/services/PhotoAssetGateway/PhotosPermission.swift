//
//  PhotosPermission.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-26.
//

import Photos

enum PhotosAuthState { case notDetermined, limited, authorized, denied }

enum PhotosAuth {
    static func state() -> PhotosAuthState {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: return .authorized
        case .limited:    return .limited
        case .notDetermined: return .notDetermined
        default: return .denied
        }
    }

    static func requestIfNeeded() async -> PhotosAuthState {
        if case .notDetermined = state() {
            let s = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return (s == .authorized ? .authorized : (s == .limited ? .limited : .denied))
        }
        return state()
    }
}
