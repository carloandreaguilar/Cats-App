//
//  DefaultBreedsDataSourceTests.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 20/10/25.
//

import Testing
@testable import Cats_App

@MainActor
@Suite("DefaultBreedsDataSourceTests")
struct DefaultBreedsDataSourceTests {
    var network: MockNetworkService!
    var persistence: MockPersistenceService!
    var sut: DefaultBreedsDataSource!

    init() {
        network = MockNetworkService()
        persistence = MockPersistenceService()
        sut = DefaultBreedsDataSource(networkService: network, persistenceService: persistence, pageSize: 3)
    }

    @Test
    func testLoadInitialPageOnlineFetchesFromNetworkAndPersists() async throws {
        let dtos = [
            CatBreedDTO(id: "1", name: "Siamese"),
            CatBreedDTO(id: "2", name: "Persian")
        ]
        network.allBreeds = dtos
        
        let page = try await sut.loadInitialPage(query: nil, mode: .online)
        
        #expect(network.fetchBreedsCalled)
        #expect(!network.searchBreedsCalled)
        #expect(persistence.persistedDtos == dtos)
        #expect(page?.items.map(\.name) == ["Siamese", "Persian"])
        #expect(page?.dataSourceMode == .online)
    }

    @Test
    func testNextNextPageUsesCurrentMode() async throws {
        network.allBreeds = [
            CatBreedDTO(id: "1", name: "Abyssinian"),
            CatBreedDTO(id: "2", name: "Balinese"),
            CatBreedDTO(id: "3", name: "Aegan"),
            CatBreedDTO(id: "4", name: "Chausie"),
            CatBreedDTO(id: "5", name: "Persian")
        ]
        
        persistence.allBreeds = network.allBreeds.map { CatBreed($0) }
        
        let onlinePage = try await sut.loadInitialPage(query: nil, mode: .online)
        #expect(onlinePage?.dataSourceMode == .online)
        let nextOnlinePage = try await sut.loadNextPage()
        #expect(nextOnlinePage?.dataSourceMode == .online)
        let offlinePage = try await sut.loadInitialPage(query: nil, mode: .offline)
        #expect(offlinePage?.dataSourceMode == .offline)
        let nextOfflinePage = try await sut.loadNextPage()
        #expect(nextOfflinePage?.dataSourceMode == .offline)
    }
    
    @Test
    func testNetworkPagination() async throws {
        network.allBreeds = [
            CatBreedDTO(id: "1", name: "Abyssinian"),
            CatBreedDTO(id: "2", name: "Balinese"),
            CatBreedDTO(id: "3", name: "Aegan"),
            CatBreedDTO(id: "4", name: "Chausie"),
            CatBreedDTO(id: "5", name: "Persian")
        ]
        
        let firstPage = try await sut.loadInitialPage(query: nil, mode: .online)
        #expect(network.fetchBreedsCalled)
        #expect(firstPage?.page == 1)
        #expect(firstPage?.items.last?.name == "Aegan")

        let nextPage = try await sut.loadNextPage()
        #expect(nextPage?.page == 2)
        #expect(nextPage?.items.last?.name == "Persian")
    }
    
    @Test
    func testChangingMode() async throws {
        network.allBreeds = [
            CatBreedDTO(id: "1", name: "Abyssinian"),
            CatBreedDTO(id: "2", name: "Balinese"),
            CatBreedDTO(id: "3", name: "Aegan"),
            CatBreedDTO(id: "4", name: "Chausie"),
            CatBreedDTO(id: "5", name: "Persian")
        ]
        
        persistence.allBreeds = [
            CatBreed(CatBreedDTO(id: "2", name: "Balinese")),
            CatBreed(CatBreedDTO(id: "3", name: "Aegan")),
            CatBreed(CatBreedDTO(id: "4", name: "Chausie")),
            CatBreed(CatBreedDTO(id: "5", name: "Persian"))
        ]
        
        let firstOnlinePage = try await sut.loadInitialPage(query: nil, mode: .online)
        #expect(network.fetchBreedsCalled)
        #expect(firstOnlinePage?.page == 1)
        #expect(firstOnlinePage?.items.last?.name == "Aegan")
        #expect(firstOnlinePage?.dataSourceMode == .online)

        let firstOfflinePage = try await sut.loadInitialPage(query: nil, mode: .offline)
        #expect(firstOfflinePage?.page == 1)
        #expect(firstOfflinePage?.items.last?.name == "Chausie")
        #expect(firstOfflinePage?.dataSourceMode == .offline)
    }
}

extension DefaultBreedsDataSourceTests {
    
    final class MockNetworkService: BreedsNetworkService {
        var searchBreedsCalled = false
        var fetchBreedsCalled = false
        var allBreeds: [CatBreedDTO] = []

        func fetchBreeds(page: Int, pageSize: Int) async throws -> [CatBreedDTO] {
            fetchBreedsCalled = true
            let start = max((page - 1) * pageSize, 0)
            let end = min(start + pageSize, allBreeds.count)
            return Array(allBreeds[start..<end])
        }

        func searchBreeds(matching query: String, page: Int, pageSize: Int) async throws -> [CatBreedDTO] {
            searchBreedsCalled = true
            let start = max((page - 1) * pageSize, 0)
            let end = min(start + pageSize, allBreeds.count)
            return Array(allBreeds[start..<end])
        }
    }

    final class MockPersistenceService: BreedsPersistenceService {
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
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
