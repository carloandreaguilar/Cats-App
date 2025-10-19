//
//  MainView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) var modelContext
    
    @State private var allBreedsNavigationPath = NavigationPath()
    @State private var favouriteBreedsNavigationPath = NavigationPath()
    
    var body: some View {
        TabView {
            Tab(AllBreedsView.defaultTitle, systemImage: "cat") {
                NavigationStack(path: $allBreedsNavigationPath) {
                    AllBreedsView(
                        viewModel:
                            AllBreedsView.DefaultViewModel(
                            breedsDataSource: DefaultBreedsDataSource(
                                networkService: DefaultBreedsNetworkService(),
                                persistenceService: DefaultBreedsPersistenceService(modelContext: modelContext)
                            ), toggleFavouriteUseCase: .init(modelContext: modelContext)
                        ), navigationPath: $allBreedsNavigationPath
                    )
                    .navigationTitle(AllBreedsView.defaultTitle)
                }
            }
            
            Tab(FavouriteBreedsView.defaultTitle, systemImage: "heart") {
                NavigationStack(path: $favouriteBreedsNavigationPath) {
                    FavouriteBreedsView(
                        viewModel:
                            FavouriteBreedsView.DefaultViewModel(
                            toggleFavouriteUseCase: .init(modelContext: modelContext)),
                        navigationPath: $favouriteBreedsNavigationPath
                    )
                    .navigationTitle(FavouriteBreedsView.defaultTitle)
                }
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: CatBreed.self, inMemory: true)
}
