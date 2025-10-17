//
//  BreedsGridView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import SwiftUI

struct BreedsGridView: View {
    private let breeds: [CatBreed]
    private let imageCornerRadius: CGFloat = 12
    private let favouriteButtonHeight: CGFloat = 20
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private let onLastItemAppear: (() async -> Void)?
    
    init(_ breeds: [CatBreed], onlastItemAppear: (() async -> Void)? = nil) {
        self.breeds = breeds
        self.onLastItemAppear = onlastItemAppear
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(breeds, id: \.id) { breed in
                gridItem(for: breed)
                    .task {
                        if breed.id == breeds.last?.id {
                            await onLastItemAppear?()
                        }
                    }
            }
        }
    }
    
    func gridItem(for breed: CatBreed) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                image(url: breed.imageURL)
                Button {
                    
                } label: {
                    Image(systemName: "heart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: favouriteButtonHeight)
                        .padding((max(0, .minimumHitSize - favouriteButtonHeight)) / 2)
                        .foregroundStyle(Color.primary)
                }
            }
            Text(breed.name)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
    
    func image(url: URL?) -> some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
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
                .animation(.default, value: true)
            } else {
                emptyImageBackground
                    .overlay {
                        Text("No image")
                            .foregroundStyle(.secondary)
                    }
                
            }
        }
        .clipped()
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(imageCornerRadius)
    }
    
    var emptyImageBackground: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.5))
    }
}

