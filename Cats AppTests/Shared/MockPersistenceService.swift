//
//  MockBreedsPersistenceService.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 21/10/25.
//

import SwiftData
@testable import Cats_App

final class MockBreedsPersistenceService: BreedsPersistenceService {
    var stored: [CatBreed] = []
    var persistedDtos: [CatBreedDTO] = []
    var allBreeds: [CatBreed] = []
    
    func fetchPersistedBreeds(query: String?, page: Int, pageSize: Int) throws -> [CatBreed] {
        let start = max((page - 1) * pageSize, 0)
        let end = min(start + pageSize, allBreeds.count)
        return Array(allBreeds[start..<end])
    }
    
    func persist(_ breedDtos: [CatBreedDTO]) throws -> [CatBreed] {
        persistedDtos = breedDtos
        let breeds = breedDtos.map { CatBreed($0) }
        stored.append(contentsOf: breeds)
        return breeds
    }
}
