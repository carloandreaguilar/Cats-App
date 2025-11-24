//
//  FavouriteBreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation
import Observation
import SwiftUI

protocol FavouritesViewModel {
    var navigationPath: Binding<NavigationPath> { get set }
    func formattedAverageLifespan(for breeds: [CatBreed]) -> String?
    func toggleFavourite(for breed: CatBreed) throws
}

@Observable
class DefaultFavouritesViewModel: FavouritesViewModel {
    var navigationPath: Binding<NavigationPath>
    private let toggleFavouriteUseCase: ToggleFavouriteUseCase
    private let formatter = NumberFormatter()
    
    init(toggleFavouriteUseCase: ToggleFavouriteUseCase, navigationPath: Binding<NavigationPath>) {
        self.toggleFavouriteUseCase = toggleFavouriteUseCase
        self.navigationPath = navigationPath
    }
    
    func formattedAverageLifespan(for breeds: [CatBreed]) -> String? {
        let lifespans: [Double] = breeds.compactMap { breed in
            guard let lifespan = breed.maxLifespan else { return nil }
            return Double(lifespan)
        }
        guard !lifespans.isEmpty else { return nil }

        let average = lifespans.reduce(0, +) / Double(lifespans.count)

        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.locale = .current

        return formatter.string(from: NSNumber(value: average))
    }
    
    func toggleFavourite(for breed: CatBreed) throws {
        try toggleFavouriteUseCase.toggle(for: breed)
    }
}

