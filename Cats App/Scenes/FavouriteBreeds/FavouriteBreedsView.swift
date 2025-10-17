//
//  FavouriteBreedsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI

struct FavouriteBreedsView: View {
    static let defaultTitle = "Favourites"
    
    @State private var viewModel: ViewModel
    
    init(viewModel: ViewModel = DefaultViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                averageLifeSpanView
                BreedsGridView(viewModel.breeds)
            }
            .padding(.horizontal)
        }
        .onAppear {
            viewModel.loadBreeds()
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
