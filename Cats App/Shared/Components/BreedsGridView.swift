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
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
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
                .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 8) {
            image(url: breed.imageURL)
            Text(breed.name)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 18))
                .foregroundStyle(Color.primary)
            Button {
                onFavouriteTap(breed)
            } label: {
                Image(systemName: (breed.isFavourited ?? false) ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: favouriteButtonHeight)
                    .foregroundStyle(Color.primary)
                ///  Making sure the tappable area conforms to guidelines minimum of 44x44
                    .extraTappableArea((max(0, .minimumHitSize - favouriteButtonHeight)) / 2)
                    
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .padding(.bottom, 8)
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
                                .overlay(
                                    /// Thin border around image, to make image shape visible when image background matches the app background.
                                    RoundedRectangle(cornerRadius: imageCornerRadius)
                                        .stroke(Color.secondary, lineWidth: 0.5)
                                )
                        }
                    case .failure:
                        emptyImageBackground
                            .overlay {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.secondary)
                            }
                    default:
                        emptyImageBackground
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

