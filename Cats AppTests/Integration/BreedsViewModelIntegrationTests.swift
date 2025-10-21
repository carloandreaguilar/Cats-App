//
//  BreedsViewModelIntegrationTests.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 21/10/25.
//

import Testing
import SwiftData
@testable import Cats_App

@MainActor
@Suite("BreedsViewModelIntegration")
struct BreedsViewModelIntegrationTests {
    
    let pageSize = 3
    let mockNetwork: MockBreedsNetworkService!
    let persistence: BreedsPersistenceService!
    let viewModel: BreedsView.ViewModel!
    
    init() {
        self.mockNetwork = MockBreedsNetworkService()
        let container = try! ModelContainer(for: CatBreed.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        self.persistence = DefaultBreedsPersistenceService(modelContext: context)
        let dataSource = DefaultBreedsDataSource(networkService: mockNetwork, persistenceService: persistence, pageSize: pageSize)
        self.viewModel = BreedsView.DefaultViewModel(breedsDataSource: dataSource, toggleFavouriteUseCase: .init(modelContext: context))
    }
    
    @Test
    func testPaginateAndPersist() async throws {
        let mockNetworkItems = [
            CatBreedDTO(id: "1", name: "Abyssinian"),
            CatBreedDTO(id: "2", name: "Balinese"),
            CatBreedDTO(id: "3", name: "Aegan"),
            CatBreedDTO(id: "4", name: "Chausie"),
            CatBreedDTO(id: "5", name: "Persian")
        ]
        mockNetwork.allBreeds = mockNetworkItems

        /// Should attempt to load from network first
        try await viewModel.loadFirstPage()
        
        /// First page of items should now be persisted.
        let firstPagePrsistedItems = try persistence.fetchPersistedBreeds(query: nil, page: 1, pageSize: pageSize)
        #expect(firstPagePrsistedItems.count == min(pageSize, mockNetworkItems.count))
        for item in mockNetworkItems.prefix(pageSize) {
            #expect(firstPagePrsistedItems.map(\.id).contains(item.id))
        }
        
        await viewModel.loadNextPageIfNeeded()
        
        /// Second page of items should now be persisted.
        let secondPagePersistedItems = try persistence.fetchPersistedBreeds(query: nil, page: 2, pageSize: pageSize)
        #expect(secondPagePersistedItems.count == min(pageSize, (mockNetworkItems.count - pageSize)))
        for item in mockNetworkItems[(pageSize)..<mockNetworkItems.count] {
            #expect(secondPagePersistedItems.map(\.id).contains(item.id))
        }
        #expect(secondPagePersistedItems.map(\.id).contains(mockNetworkItems.last?.id))
        
        let totalPersistedItems = try persistence.fetchPersistedBreeds(query: nil, page: 1, pageSize: .max)
        #expect(totalPersistedItems.count == mockNetworkItems.count)
        for item in mockNetworkItems {
            #expect(totalPersistedItems.map(\.id).contains(item.id))
        }
        
        #expect(viewModel.breeds.count == mockNetworkItems.count)
        #expect(viewModel.breeds.last?.id == mockNetworkItems.last?.id)
    }
    
    @Test
    func testActivateOfflineMode() async throws {
        let mockNetworkItems = [
            CatBreedDTO(id: "1", name: "Abyssinian"),
            CatBreedDTO(id: "2", name: "Balinese"),
            CatBreedDTO(id: "3", name: "Aegan"),
            CatBreedDTO(id: "4", name: "Chausie"),
            CatBreedDTO(id: "5", name: "Persian")
        ]
        mockNetwork.allBreeds = mockNetworkItems

        /// Should attempt to load from network first
        try await viewModel.loadFirstPage()
        
        if case .loaded(let properties) = viewModel.viewState {
            #expect(properties.dataSourceMode == .online)
            #expect(viewModel.breeds.count == min(pageSize, mockNetworkItems.count))
        } else {
            Issue.record("Wrong view state")
        }
      
        try await viewModel.activateOfflineMode()
        
        if case .loaded(let properties) = viewModel.viewState {
            #expect(properties.dataSourceMode == .offline)
            /// First page of items should now be persisted.
            #expect(viewModel.breeds.count == min(pageSize, mockNetworkItems.count))
        } else {
            Issue.record("Wrong view state")
        }
    }
    
    @Test
    func testReconnect() async throws {
        let mockNetworkItems = [
            CatBreedDTO(id: "1", name: "Abyssinian"),
            CatBreedDTO(id: "2", name: "Balinese"),
            CatBreedDTO(id: "3", name: "Aegan"),
            CatBreedDTO(id: "4", name: "Chausie"),
            CatBreedDTO(id: "5", name: "Persian")
        ]
        mockNetwork.allBreeds = mockNetworkItems

        /// Should attempt to load from network first
        try await viewModel.loadFirstPage()
        
        if case .loaded(let properties) = viewModel.viewState {
            #expect(properties.hasConnection == true)
        } else {
            Issue.record("Wrong view state")
        }
        
        mockNetwork.shouldThrowError = true
      
        await viewModel.loadNextPageIfNeeded()
        
        if case .loaded(let properties) = viewModel.viewState {
            #expect(properties.hasConnection == false)
        } else {
            Issue.record("Wrong view state")
        }
        
        do {
            try await viewModel.attemptNetworkRefresh()
            Issue.record("Expected to fail")
        } catch {}
        
        mockNetwork.shouldThrowError = false
        
        do {
            try await viewModel.attemptNetworkRefresh()
        } catch {
            Issue.record("Not expected to fail")
        }
        
        if case .loaded(let properties) = viewModel.viewState {
            #expect(properties.hasConnection == true)
        } else {
            Issue.record("Wrong view state")
        }
    }
}
