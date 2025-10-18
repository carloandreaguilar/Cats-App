//
//  FavouriteBreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//


import Observation

extension FavouriteBreedsView {
    
    protocol ViewModel {
        func averageLifespan(for breeds: [CatBreed]) -> Double
    }
    
    @Observable
    class DefaultViewModel: ViewModel {
        func averageLifespan(for breeds: [CatBreed]) -> Double {
            let lifespans: [Double] = breeds.compactMap { breed in
                guard let maxLifespan = breed.maxLifespan else { return nil }
                return Double(maxLifespan)
            }
           
            let total = lifespans.reduce(0, +)
            return total / Double(lifespans.count)
        }
    }
}
