//
//  CatsListView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI

struct CatsListView: View {
    static let defaultTitle = "All Breeds"
    
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            CatBreedsGridView(breeds: MockData.breeds)
                .padding(.horizontal)
        }
        .searchable(text: $searchText)
    }
}

#Preview {
    CatsListView()
}

struct MockData {
    static let breeds: [CatBreed] = [
        .init(id: "persian", name: "Persian"),
        .init(id: "siamese", name: "Siamese"),
        .init(id: "sphynx", name: "Sphynx"),
        .init(id: "birman", name: "Birman"),
    ]
}
