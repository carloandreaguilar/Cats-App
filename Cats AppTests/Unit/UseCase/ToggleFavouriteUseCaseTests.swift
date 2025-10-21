//
//  ToggleFavouriteUseCaseTests.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 20/10/25.
//

import Foundation
import Testing
import SwiftData
@testable import Cats_App

@MainActor
@Suite("ToggleFavouriteUseCase")
struct ToggleFavouriteUseCaseTests {
    
    @Test
    func testToggleFavourite() throws {
        let container = try! ModelContainer(for: CatBreed.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let useCase = ToggleFavouriteUseCase(modelContext: context)
        let cat = CatBreed(CatBreedDTO(id: "1", name: "Cat"))
        context.insert(cat)
        #expect((cat.isFavourited ?? false) == false)
        try useCase.toggle(for: cat)
        #expect(cat.isFavourited == true)
        
        
        /// Check if it saved
        let id = String(cat.id)
        let descriptor = FetchDescriptor<CatBreed>(
            predicate: #Predicate { $0.id == id }
        )
        let results = try context.fetch(descriptor)
        #expect(results.first?.isFavourited == true)
    }
}
