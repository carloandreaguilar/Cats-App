//
//  FavouriteBreedsViewModelTests.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 21/10/25.
//

import Testing
import Observation
import SwiftData
@testable import Cats_App

@MainActor
@Suite("FavouriteBreedsViewModel")
struct FavouriteBreedsViewModelTests {
    
    let sut: FavouriteBreedsView.DefaultViewModel
    
    init() {
        let container = try! ModelContainer(for: CatBreed.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        self.sut = .init(toggleFavouriteUseCase: .init(modelContext: context))
    }
    
    @Test
    func testAverageLifespan() {
        let breeds = [
            CatBreed(id: "A", name: "BreedA", maxLifespan: 15),
            CatBreed(id: "B", name: "BreedB", maxLifespan: 10),
            CatBreed(id: "C", name: "BreedC", maxLifespan: 5)
        ]
        let average = sut.averageLifespan(for: breeds)
        #expect(average == 10.0)
    }
    
    @Test
    func testAverageLifespanWithMissingLifespanValues() {
        let breeds = [
            CatBreed(id: "A", name: "BreedA", maxLifespan: 12),
            CatBreed(id: "B", name: "BreedB", maxLifespan: nil),
            CatBreed(id: "C", name: "BreedC", maxLifespan: 5)
        ]
        
        let average = sut.averageLifespan(for: breeds)
        #expect(average == 8.5)
    }
    
    @Test
    func testAverageLifespanWithEmptyArray() {
        let average = sut.averageLifespan(for: [])
        #expect(average == 0)
    }
}
