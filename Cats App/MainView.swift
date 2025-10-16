//
//  MainView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    var body: some View {
        TabView {
            Tab(CatsListView.defaultTitle, systemImage: "cat") {
                NavigationStack {
                    CatsListView()
                        .navigationTitle(CatsListView.defaultTitle)
                }
            }
            Tab(FavouriteCatsView.defaultTitle, systemImage: "heart") {
                NavigationStack {
                    FavouriteCatsView()
                        .navigationTitle(FavouriteCatsView.defaultTitle)
                }
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: CatBreed.self, inMemory: true)
}
