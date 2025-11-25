//
//  BreedsViewModelTests.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 20/10/25.
//

import Testing
import Observation
import SwiftData
import SwiftUI
@testable import Cats_App

@MainActor
@Suite("BreedsViewModel")
struct BreedsViewModelTests {
    let mockDataSource: MockBreedsDataSource!
    let sut: DefaultBreedsViewModel!

    init() {
        mockDataSource = MockBreedsDataSource()
        let container = try! ModelContainer(for: CatBreed.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        sut = DefaultBreedsViewModel(
            breedsDataSource: mockDataSource,
            toggleFavouriteUseCase: DefaultToggleFavouriteUseCase(modelContext: context)
        )
    }
    
    @Test
    func testViewStateChanges() async throws {
        let firstPage = Page(
            items: [CatBreed(CatBreedDTO(id: "1", name: "A"))],
            page: 1, hasMore: true, dataSourceMode: .online
        )
        let nextPage = Page(
            items: [CatBreed(CatBreedDTO(id: "2", name: "B"))],
            page: 2, hasMore: false, dataSourceMode: .online
        )
        mockDataSource.pageQueue = [firstPage, nextPage]
        mockDataSource.shouldDelay = true

        actor StateRecorder {
            var values: [BreedsViewState] = []
            func append(_ state: BreedsViewState) { values.append(state) }
            func snapshot() -> [BreedsViewState] { values }
        }
        let recorder = StateRecorder()

        @MainActor
        func observeStateChanges() {
            withObservationTracking {
                _ = sut.viewState
            } onChange: {
                Task { @MainActor in
                    await recorder.append(sut.viewState)
                    observeStateChanges()
                }
            }
        }

        await recorder.append(sut.viewState)
        observeStateChanges()
        try await sut.loadFirstPage()
        try await Task.sleep(for: .seconds(1))
        await sut.loadNextPageIfNeeded()
        try await Task.sleep(for: .seconds(1))
        
        
        
        let observedStates = await recorder.snapshot()
        let expectedStates: [BreedsViewState] = [
            .loadingFirstPage,
            .loaded(properties: .init(hasMore: true, loadingMore: false, isReload: true)),
            .loaded(properties: .init(hasMore: true, loadingMore: true, isReload: false)),
            .loaded(properties: .init(hasMore: false))
        ]
        #expect(observedStates == expectedStates)
    }

    @Test
    func testLoadFirstPageSuccess() async throws {
        mockDataSource.pageToReturn = Page(
            items: [CatBreed(CatBreedDTO(id: "1", name: "Siamese"))],
            page: 1,
            hasMore: true,
            dataSourceMode: .online
        )

        try await sut.loadFirstPage()

        #expect(sut.viewState == .loaded(properties: .init(hasMore: true, isReload: true)))
        #expect(sut.hasConnection)
        #expect(sut.dataSourceMode == .online)
        #expect(sut.breeds.count == mockDataSource.pageToReturn?.items.count)
        #expect(sut.breeds.first == mockDataSource.pageToReturn?.items.first)
    }

    @Test
    func testLoadFirstPageNetworkError() async {
        mockDataSource.shouldThrowNetworkError = true

        do {
            try await sut.loadFirstPage()
            Issue.record("Expected error not thrown")
        } catch {
            #expect(sut.viewState == .loaded(properties: .init(hasMore: true)))
            #expect(!sut.hasConnection)
            #expect(sut.dataSourceMode == .online)
        }
    }

    @Test
    func testAppendingPages() async throws {
        let firstPage = Page(
            items: [CatBreed(CatBreedDTO(id: "1", name: "Siamese"))],
            page: 1,
            hasMore: true,
            dataSourceMode: .online
        )
        let nextPage = Page(
            items: [CatBreed(CatBreedDTO(id: "2", name: "Persian"))],
            page: 2,
            hasMore: false,
            dataSourceMode: .online
        )
        mockDataSource.pageQueue = [firstPage, nextPage]
        
        let expected = firstPage.items + nextPage.items

        try await sut.loadFirstPage()
        await sut.loadNextPageIfNeeded()

        #expect(sut.breeds == expected)
        #expect(sut.viewState == .loaded(properties: .init(hasMore: false, isReload: false)))
        #expect(sut.hasConnection)
        #expect(sut.dataSourceMode == .online)
    }
    
    @Test
    func testLoadNextPageDoesNothingIfHasMoreIsFalse() async throws {
        mockDataSource.pageToReturn = Page(
            items: [],
            page: 1,
            hasMore: false,
            dataSourceMode: .online
        )
        try await sut.loadFirstPage()

        await sut.loadNextPageIfNeeded()

        #expect(mockDataSource.loadNextPageCallCount == 0)
        #expect(sut.viewState == .loaded(properties: .init(hasMore: false, isReload: true)))
        #expect(sut.hasConnection)
        #expect(sut.dataSourceMode == .online)
    }

    @Test
    func testLoadFirstPageNetworkErrorSetsHasConnectionFalse() async {
        mockDataSource.shouldThrowNetworkError = true

        do {
            try await sut.loadFirstPage()
            Issue.record("Expected network error not thrown")
        } catch {
            #expect(sut.viewState == .loaded(properties: .init(hasMore: true)))
            #expect(!sut.hasConnection)
        }
    }

    @Test
    func testUpdateDataNilPageSetsHasMoreFalse() async throws {
        mockDataSource.pageToReturn = Page(
            items: [],
            page: 1,
            hasMore: true,
            dataSourceMode: .online
        )
        try await sut.loadFirstPage()
        mockDataSource.pageToReturn = nil
        await sut.loadNextPageIfNeeded()
        switch sut.viewState {
        case .loaded(let properties):
            #expect(properties.hasMore == false)
        default:
            Issue.record("Expected loaded state")
        }
    }
}
