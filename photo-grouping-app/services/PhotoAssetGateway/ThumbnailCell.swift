//
//  ThumbnailCell.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-29.
//

import SwiftUI

struct ThumbnailCell: View {
    let ref: PhotoRef
    let gw: PhotosKitGateway
    @State private var uiImage: UIImage?

    var body: some View {
        ZStack {
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 100)
                    .overlay(ProgressView().scaleEffect(0.8))
            }
        }
        .task {
            // fetch once when the cell appears
            do { uiImage = try await gw.thumbnail(for: ref.id) }
            catch { print("thumb fetch failed:", error) }
        }
    }
}
