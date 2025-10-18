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
    
    var body: some View {
        TabView {
            
            Tab(AllBreedsView.defaultTitle, systemImage: "cat") {
                NavigationStack {
                    AllBreedsView(
                        viewModel: AllBreedsView.DefaultViewModel(
                            breedsDataSource: DefaultBreedsDataSource(
                                cacheService: DefaultBreedsCacheService(modelContext: modelContext),
                                networkClient: DefaultBreedsNetworkClient()
                            )
                        )
                    )
                    .navigationTitle(AllBreedsView.defaultTitle)
                }
            }
            
            Tab(FavouriteBreedsView.defaultTitle, systemImage: "heart") {
                NavigationStack {
                    FavouriteBreedsView()
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
