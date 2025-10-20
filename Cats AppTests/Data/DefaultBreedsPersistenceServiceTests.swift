//
//  DefaultBreedsPersistenceServiceTests.swift
//  Cats AppTests
//
//  Created by Carlo André Aguilar on 20/10/25.
//

import Testing
import Foundation
import SwiftData
@testable import Cats_App

@MainActor
@Suite("DefaultBreedsPersistenceServiceTests")
struct DefaultBreedsPersistenceServiceTests {
    var context: ModelContext!
    var sut: DefaultBreedsPersistenceService!

    init() throws {
        let container = try ModelContainer(for: CatBreed.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
        sut = DefaultBreedsPersistenceService(modelContext: context)
    }

    @Test
    func testPersistNew() async throws {
        let dtos = [
            CatBreedDTO(id: "abc", name: "Siamese"),
            CatBreedDTO(id: "def", name: "Persian")
        ]

        let result = try sut.persist(dtos)
        /// Result should be in the same order as input
        #expect(result.first!.id == dtos.first!.id)
        #expect(result.count == dtos.count)
        let fetched = try context.fetch(FetchDescriptor<CatBreed>())
        #expect(fetched.count == dtos.count)
        #expect(fetched.contains(result[0]))
        #expect(fetched.contains(result[1]))
    }

    @Test
    func testUpdateExisting() async throws {
        let existing = CatBreed(CatBreedDTO(id: "abc", name: "Old Name"))
        context.insert(existing)
        try context.save()

        let updated = try sut.persist([CatBreedDTO(id: "abc", name: "New Name")])

        #expect(updated.first?.name == "New Name")
        let fetched = try context.fetch(FetchDescriptor<CatBreed>())
        /// Make sure its the same reference, not a copy
        #expect(fetched == updated)
    }

    @Test
    func testFetchPagination() async throws {
        let breeds = (1...18).map { CatBreed(CatBreedDTO(id: "\($0)", name: "Breed \($0)")) }
        breeds.forEach { context.insert($0) }
        try context.save()

        let filtered = try sut.fetchPersistedBreeds(query: "breed 1", page: 1, pageSize: 10)
        let paginated = try sut.fetchPersistedBreeds(query: nil, page: 4, pageSize: 5)

        /// Would fetch the first and  all the ones in the "teens". 10, 11, 12, etc.
        #expect(filtered.count == 10)
        #expect(paginated.count == 3)
        #expect(paginated.first?.name == "Breed 16")
    }
}
