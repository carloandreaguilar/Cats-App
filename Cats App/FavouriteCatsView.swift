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
            CatBreedsGridView(breeds: MockData.breeds)
                .padding(.horizontal)
        }
    }
}

#Preview {
    FavouriteCatsView()
}
