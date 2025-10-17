//
//  AllBreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Observation

extension AllBreedsView {
    
    protocol ViewModel {
        var breeds: [CatBreed] { get }
        func loadBreeds() async
    }
    
    @Observable
    class DefaultViewModel: ViewModel {
        private(set) var breeds: [CatBreed] = []
        
        func loadBreeds() async {
            self.breeds = MockData.breeds
        }
    }
}
