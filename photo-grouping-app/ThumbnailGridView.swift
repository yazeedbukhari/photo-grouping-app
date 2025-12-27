//
//  ThumbnailGridView.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-10-28.
//

import SwiftUI

struct ThumbnailGridView: View { // front-end
    @State private var photos: [PhotoRef] = []
    @State private var gw: PhotosKitGateway?
    
    var body: some View { // runs at init or at state variable change
        ScrollView() {
            if let gw {
                LazyVGrid(columns:[GridItem(.adaptive(minimum: 100))])  { // minimum refers to pixel width, specify by pixel size as this app could be used on ipad or different sized phones
                    ForEach(photos, id: \.id.raw) { ref in
                        ThumbnailCell(ref: ref, gw: gw)
                    }
                }
            }
            else {
                Text("Awaiting permission...")
            }
        }
        .task { // runs only when the view shows
            let state = await PhotosAuth.requestIfNeeded() // waits until permission is gotten
            guard case .authorized = state else { return }

            let gateway = PhotosKitGateway()
            gw = gateway
            photos = gateway.listRecent(limit: 5)
        }
    }
}
