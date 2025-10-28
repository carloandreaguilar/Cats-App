//
//  AppDependencies.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 24/10/25.
//

import SwiftUI
import SwiftData

protocol AppDependencies {
    var breedsDataSource: BreedsDataSource { get }
    var toggleFavouriteUseCase: ToggleFavouriteUseCase { get }
    var modelContainer: ModelContainer { get }
    var urlCache: URLCache { get }
    func makeBreedsViewModel() -> BreedsViewModel
    func makeFavouritesViewModel() -> FavouritesViewModel
    func makeDetailViewModel(breed:CatBreed) -> BreedDetailViewModel
}

struct DefaultAppDependencies: AppDependencies {
    let breedsDataSource: BreedsDataSource
    let toggleFavouriteUseCase: ToggleFavouriteUseCase
    let modelContainer: ModelContainer
    let urlCache: URLCache
    
    init() {
        let modelContainer: ModelContainer = {
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
        
        let modelContext = modelContainer.mainContext
        
        let breedsDataSource = DefaultBreedsDataSource(
            networkService: DefaultBreedsNetworkService(),
            persistenceService: DefaultBreedsPersistenceService(modelContext: modelContext))
        
        let toggleFavouriteUseCase = DefaultToggleFavouriteUseCase(modelContext: modelContext)
        
        // Increased Capacity for image caching
        let urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50mb
            diskCapacity: 100 * 1024 * 1024 // 100mb
        )

        self.breedsDataSource = breedsDataSource
        self.toggleFavouriteUseCase = toggleFavouriteUseCase
        self.modelContainer = modelContainer
        self.urlCache = urlCache
    }
    
    func makeBreedsViewModel() -> BreedsViewModel {
        return DefaultBreedsViewModel(
            breedsDataSource: breedsDataSource, toggleFavouriteUseCase: toggleFavouriteUseCase)
    }
    
    func makeFavouritesViewModel() -> FavouritesViewModel {
        return DefaultFavouritesViewModel(toggleFavouriteUseCase: toggleFavouriteUseCase)
    }
    
    func makeDetailViewModel(breed:CatBreed) -> BreedDetailViewModel {
        return DefaultBreedDetailViewModel(breed: breed, toggleFavouriteUseCase: toggleFavouriteUseCase)
    }
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies = DefaultAppDependencies()
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
