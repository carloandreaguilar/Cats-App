//
//  FavouriteBreedsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI

struct FavouriteBreedsView: View {
    static let defaultTitle = "Favourites"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                averageLifeSpanView
                BreedsGridView(MockData.breeds)
            }
            .padding(.horizontal)
        }
    }
    
    var averageLifeSpanView: some View {
        Text("Average lifespan: ")
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

#Preview {
    FavouriteBreedsView()
}
