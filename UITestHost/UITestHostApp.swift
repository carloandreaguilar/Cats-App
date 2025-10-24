//
//  UITestHostApp.swift
//  UITestHost
//
//  Created by Carlo André Aguilar on 25/10/25.
//

import SwiftUI
import SwiftData

extension AppDependencies {
    static var uiTesting: Self {
        let sharedModelContainer: ModelContainer = {
            let schema = Schema([
                CatBreed.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
        let modelContext = ModelContext(sharedModelContainer)
        
        let breedsViewModel = DefaultBreedsViewModel(
            breedsDataSource: DefaultBreedsDataSource(
                networkService: DefaultBreedsNetworkService(),
                persistenceService: DefaultBreedsPersistenceService(modelContext: modelContext)
            ), toggleFavouriteUseCase: ToggleFavouriteUseCase(modelContext: modelContext)
        )
        
        let favouritesViewModel = DefaultFavouritesViewModel(
        toggleFavouriteUseCase: ToggleFavouriteUseCase(modelContext: modelContext))
        
        return .init(breedsViewModel: breedsViewModel, favouritesViewModel: favouritesViewModel, modelContainer: sharedModelContainer)
    }
}

@main
struct UITestHostApp: App {
    private let dependencies = AppDependencies.uiTesting

    var body: some Scene {
        WindowGroup {
            MainView(appDependencies: dependencies)
        }
        .modelContainer(dependencies.modelContainer)
    }
}
