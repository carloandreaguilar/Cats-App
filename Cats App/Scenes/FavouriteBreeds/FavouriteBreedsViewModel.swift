//
//  FavouriteBreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//


import Observation

extension FavouriteBreedsView {
    
    protocol ViewModel {
        var breeds: [CatBreed] { get }
        func loadBreeds()
    }
    
    @Observable
    class DefaultViewModel: ViewModel {
        private(set) var breeds: [CatBreed] = []
        
        func loadBreeds() {
            
        }
    }
}
