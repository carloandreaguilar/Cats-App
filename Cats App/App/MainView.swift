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
    @State private var selectedTab = 0
    @State private var allBreedsNavigationPath = NavigationPath()
    @State private var favouriteBreedsNavigationPath = NavigationPath()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        TabView(selection: $selectedTab) {
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
            .tabItem {
                Label(AllBreedsView.defaultTitle, systemImage: "cat")
            }
            .tag(0)

            NavigationStack(path: $favouriteBreedsNavigationPath) {
                FavouriteBreedsView(
                    viewModel:
                        FavouriteBreedsView.DefaultViewModel(
                        toggleFavouriteUseCase: .init(modelContext: modelContext)),
                    navigationPath: $favouriteBreedsNavigationPath
                )
                .navigationTitle(FavouriteBreedsView.defaultTitle)
            }
            .tabItem {
                Label(FavouriteBreedsView.defaultTitle, systemImage: "heart")
            }
            .tag(1)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            hapticGenerator.prepare()
            hapticGenerator.impactOccurred()
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: CatBreed.self, inMemory: true)
}
