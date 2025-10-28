//
//  GatewayPreviewView.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-26.
//

import SwiftUI

struct GatewayPreviewView: View {
    @State private var auth: PhotosAuthState = .notDetermined
    @State private var sample: PhotoRef?
    @State private var image: UIImage?
    private let gw = PhotosKitGateway()

    var body: some View {
        VStack(spacing: 12) {
            Text("Auth: \(String(describing: auth))")
            if let img = image {
                Image(uiImage: img).resizable().scaledToFit().frame(height: 240)
            } else {
                Rectangle().fill(.gray.opacity(0.2)).frame(height: 240)
                    .overlay(Text("No image yet"))
            }
            Button("Load first photo") {
                let refs = gw.listRecent(limit: 1)
                sample = refs.first
                Task {
                    guard let id = refs.first?.id else { return }
                    do {
                        let img = try await gw.fetchImage(for: id, target: CGSize(width: 1200, height: 1200))
                        image = img
                    } catch {
                        print("fetch error:", error)
                    }
                }
            }
        }
        .padding()
        .task {
            auth = await PhotosAuth.requestIfNeeded()
        }
    }
}
