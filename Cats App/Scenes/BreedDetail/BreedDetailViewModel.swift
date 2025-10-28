//
//  BreedDetailViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 18/10/25.
//

import Observation

protocol BreedDetailViewModel {
    var breed: CatBreed { get }
    func toggleFavourite() throws
}

@Observable
class DefaultBreedDetailViewModel: BreedDetailViewModel {
    private(set) var breed: CatBreed
    private let toggleFavouriteUseCase: ToggleFavouriteUseCase
    
    init(breed: CatBreed, toggleFavouriteUseCase: ToggleFavouriteUseCase) {
        self.breed = breed
        self.toggleFavouriteUseCase = toggleFavouriteUseCase
    }
    
    func toggleFavourite() throws {
        try toggleFavouriteUseCase.toggle(for: breed)
    }
}
