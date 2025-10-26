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
    let urlCache: URLCache
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
        let modelContext = sharedModelContainer.mainContext
        
        let breedsViewModel = DefaultBreedsViewModel(
            breedsDataSource: DefaultBreedsDataSource(
                networkService: DefaultBreedsNetworkService(),
                persistenceService: DefaultBreedsPersistenceService(modelContext: modelContext)
            ), toggleFavouriteUseCase: ToggleFavouriteUseCase(modelContext: modelContext)
        )
        
        let favouritesViewModel = DefaultFavouritesViewModel(
        toggleFavouriteUseCase: ToggleFavouriteUseCase(modelContext: modelContext))
        
        // Increased capacity for image caching
        let urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50mb
            diskCapacity: 200 * 1024 * 1024 // 500mb
        )
        
        return .init(breedsViewModel: breedsViewModel, favouritesViewModel: favouritesViewModel, modelContainer: sharedModelContainer, urlCache: urlCache)
    }
}
