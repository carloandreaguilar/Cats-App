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
    
    @Binding private var navigationPath: NavigationPath
    
    @Query(
        filter: #Predicate { $0.isFavourited == true },
        sort: [SortDescriptor(\CatBreed.name)]
    )
    private var favourites: [CatBreed]
    
    init(viewModel: ViewModel, navigationPath: Binding<NavigationPath>) {
        self.viewModel = viewModel
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                averageLifeSpanView
                BreedsGridView(favourites,
                               onTap: { breed in
                    navigationPath.append(BreedDestination.detail(breed: breed))
                }, onFavouriteTap: { breed in
                    try? viewModel.toggleFavourite(for: breed)
                })
            }
            .padding(.horizontal)
        }
        .navigationDestination(for: BreedDestination.self, destination: { destination in
            switch destination {
            case .detail(let breed):
                BreedDetailView(viewModel: BreedDetailView.DefaultViewModel(breed: breed, toggleFavouriteUseCase: .init(modelContext: modelContext)))
            }
        })
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
    
    FavouriteBreedsView(viewModel: FavouriteBreedsView.DefaultViewModel( toggleFavouriteUseCase: .init(modelContext: context)), navigationPath: .constant(NavigationPath()))
}
