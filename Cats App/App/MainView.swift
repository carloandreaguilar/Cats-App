//
//  MainView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.appDependencies) var appDependencies
    @State private var selectedTab = 0
    @State private var breedsNavigationPath = NavigationPath()
    @State private var favouriteBreedsNavigationPath = NavigationPath()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $breedsNavigationPath) {
                BreedsView(
                    viewModel:
                        appDependencies.makeBreedsViewModel(),
                    navigationPath: $breedsNavigationPath
                )
                .navigationTitle(BreedsView.defaultTitle)
            }
            .tabItem {
                Label(BreedsView.defaultTitle, systemImage: "cat")
            }
            .tag(0)

            NavigationStack(path: $favouriteBreedsNavigationPath) {
                FavouriteBreedsView(
                    viewModel:
                        appDependencies.makeFavouritesViewModel(),
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
    let appDependencies = DefaultAppDependencies()
    MainView()
        .modelContainer(appDependencies.modelContainer)
        .environment(\.appDependencies, appDependencies)
}
