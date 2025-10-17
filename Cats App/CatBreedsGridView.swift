//
//  CatBreedsGridView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import SwiftUI

struct CatBreedsGridView: View {
    private let breeds: [CatBreed]
    private let imageCornerRadius: CGFloat = 12
    private let favouriteButtonHeight: CGFloat = 20
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    init(_ breeds: [CatBreed]) {
        self.breeds = breeds
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(breeds, id: \.id) { breed in
                gridItem(for: breed)
            }
        }
    }
    
    func gridItem(for breed: CatBreed) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.secondary)
                    .aspectRatio(1.0, contentMode: .fit)
                    .cornerRadius(imageCornerRadius)
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
}

