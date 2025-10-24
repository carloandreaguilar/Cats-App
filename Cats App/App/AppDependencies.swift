//
//  AppDependencies.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 24/10/25.
//

import SwiftUI
import SwiftData

struct AppDependencies {
    let breedsViewModel: BreedsViewModel
    let favouritesViewModel: FavouritesViewModel
    let modelContainer: ModelContainer
    
    init(breedsViewModel: BreedsViewModel, favouritesViewModel: FavouritesViewModel, modelContainer: ModelContainer) {
        self.breedsViewModel = breedsViewModel
        self.favouritesViewModel = favouritesViewModel
        self.modelContainer = modelContainer
    }
}

extension AppDependencies {
    static var production: Self {
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
