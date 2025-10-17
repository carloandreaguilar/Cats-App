//
//  AllBreedsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI

struct AllBreedsView: View {
    static let defaultTitle = "All Breeds"
    
    @State private var viewModel: ViewModel
    
    @State private var searchText = ""
    
    init(viewModel: ViewModel = DefaultViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            BreedsGridView(viewModel.breeds)
                .padding(.horizontal)
        }
        .searchable(text: $searchText)
        .task {
            await viewModel.loadBreeds()
        }
    }
}

#Preview {
    AllBreedsView(viewModel: AllBreedsView.DefaultViewModel())
}

struct MockData {
    static let breeds: [CatBreed] = [
        .init(id: "persian", name: "Persian", lifeSpan: 12 ... 15),
        .init(id: "siamese", name: "Siamese", lifeSpan: 10 ... 12),
        .init(id: "sphynx", name: "Sphynx"),
        .init(id: "birman", name: "Birman"),
    ]
}
