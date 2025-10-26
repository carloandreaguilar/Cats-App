//
//  CachedAsyncImage.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 26/10/25.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: Image? = nil
    @State private var isLoading = false

    init(url: URL?,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    init(url: URL?) where Content == Image, Placeholder == EmptyView {
        self.url = url
        self.content = { image in image }
        self.placeholder = { EmptyView() }
    }

    var body: some View {
        if let image = image {
            content(image)
        } else {
            placeholder()
                .task {
                    await loadImage()
                }
        }
    }
    
    private func loadImage() async {
        guard let url = url, image == nil, !isLoading else { return }
        isLoading = true
        
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            await MainActor.run {
                self.image = Image(uiImage: cachedImage)
                self.isLoading = false
            }
        } else {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Cache image
                let cachedData = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedData, for: request)
                
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = Image(uiImage: uiImage)
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
