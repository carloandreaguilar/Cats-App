//
//  FavouriteBreedsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI
import SwiftData

struct FavouriteBreedsView: View {
    static let defaultTitle = "Favourites"
    
    @Environment(\.modelContext) var modelContext
    
    @State private var viewModel: ViewModel
    
    @Query(
        filter: #Predicate { $0.isFavourited == true },
        sort: [SortDescriptor(\CatBreed.name)]
    )
    private var favourites: [CatBreed]
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                averageLifeSpanView
                BreedsGridView(favourites) { breed in
                    try? ToggleFavouriteUseCase.toggle(for: breed, on: modelContext)
                }
            }
            .padding(.horizontal)
        }
    }
    
    var averageLifeSpanView: some View {
        Text("Average lifespan: \(String(format: "%.1f", viewModel.averageLifespan(for: favourites)))")
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

#Preview {
    let container = try! ModelContainer(for: CatBreed.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    FavouriteBreedsView(viewModel: FavouriteBreedsView.DefaultViewModel( ))
}
