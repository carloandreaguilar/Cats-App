//
//  FavouriteCatsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI

struct FavouriteCatsView: View {
    static let defaultTitle = "Favourites"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                averageLifeSpanView
                CatBreedsGridView(MockData.breeds)
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
    FavouriteCatsView()
}
