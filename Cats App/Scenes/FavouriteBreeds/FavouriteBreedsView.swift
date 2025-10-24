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
    
    @State private var viewModel: FavouritesViewModel
    
    @Binding private var navigationPath: NavigationPath
    
    @Query(
        filter: #Predicate { $0.isFavourited == true },
        sort: [SortDescriptor(\CatBreed.name)]
    )
    private var favourites: [CatBreed]
    
    init(viewModel: FavouritesViewModel, navigationPath: Binding<NavigationPath>) {
        self.viewModel = viewModel
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        Group {
            if favourites.isEmpty {
                contentUnavailableView()
            } else {
                favouritesScrollableGrid()
            }
        }
        .navigationDestination(for: BreedDestination.self, destination: { destination in
            switch destination {
            case .detail(let breed):
                BreedDetailView(viewModel: DefaultBreedDetailViewModel(breed: breed, toggleFavouriteUseCase: ToggleFavouriteUseCase(modelContext: modelContext)))
            }
        })
    }
    
    func favouritesScrollableGrid() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                averageLifeSpanView()
                BreedsGridView(favourites,
                               onTap: { breed in
                    navigationPath.append(BreedDestination.detail(breed: breed))
                }, onFavouriteTap: { breed in
                    try? viewModel.toggleFavourite(for: breed)
                })
            }
            .padding(.horizontal)
            .padding(.bottom, AppConstants.ViewLayout.scrollViewBottomPadding)
        }
    }
    
    func contentUnavailableView() -> some View {
        ContentUnavailableView(
            "No favourites",
            systemImage: "heart.fill"
        )
        .foregroundStyle(Color.primary)
    }
    
    @ViewBuilder
    func averageLifeSpanView() -> some View {
        if let lifespan = viewModel.formattedAverageLifespan(for: favourites) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Average lifespan".uppercased())
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12, weight: .bold))
                Text("\(lifespan) years")
                    .foregroundStyle(.primary)
                    .font(.system(size: 18, weight: .bold))
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: CatBreed.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    FavouriteBreedsView(viewModel: DefaultFavouritesViewModel( toggleFavouriteUseCase: ToggleFavouriteUseCase(modelContext: context)), navigationPath: .constant(NavigationPath()))
}
