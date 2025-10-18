//
//  BreedsGridView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import SwiftUI
import CachedAsyncImage
import SwiftData

struct BreedsGridView: View {
    private let breeds: [CatBreed]
    private let imageCornerRadius: CGFloat = 12
    private let favouriteButtonHeight: CGFloat = 20
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private let onTap: ((CatBreed) -> Void)
    private let onFavouriteTap: ((CatBreed) -> Void)
    private let onLastItemAppear: (() async -> Void)?
    
    init(_ breeds: [CatBreed], onTap: @escaping ((CatBreed) -> Void), onFavouriteTap: @escaping ((CatBreed) -> Void), onlastItemAppear: (() async -> Void)? = nil) {
        self.breeds = breeds
        self.onTap = onTap
        self.onFavouriteTap = onFavouriteTap
        self.onLastItemAppear = onlastItemAppear
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(breeds, id: \.id) { breed in
                Button {
                    onTap(breed)
                } label: {
                    gridItem(for: breed)
                }
                .task {
                    if breed.id == breeds.last?.id {
                        await onLastItemAppear?()
                    }
                }
            }
        }
        .animation(.default, value: breeds.count)
    }
    
    func gridItem(for breed: CatBreed) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                image(url: breed.imageURL)
                Button {
                    onFavouriteTap(breed)
                } label: {
                    Image(systemName: (breed.isFavourited ?? false) ? "heart.fill" : "heart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: favouriteButtonHeight)
                        ///  Making sure the minimum tappable area conforms to guidelines
                        .padding((max(0, .minimumHitSize - favouriteButtonHeight)) / 2)
                        .foregroundStyle(Color.primary)
                }
            }
            Text(breed.name)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .font(.headline)
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
    
    func image(url: URL?) -> some View {
        Group {
            if let url = url {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        emptyImageBackground
                    case .success(let image):
                        GeometryReader { geometryReader in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometryReader.size.width, height: geometryReader.size.width, alignment: .center)
                        }
                    default:
                        emptyImageBackground
                            .overlay {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
            } else {
                emptyImageBackground
                    .overlay {
                        Text("No image")
                            .foregroundStyle(.secondary)
                    }
                
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .cornerRadius(imageCornerRadius)
    }
    
    var emptyImageBackground: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.5))
    }
}

