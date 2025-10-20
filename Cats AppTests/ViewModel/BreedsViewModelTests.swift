//
//  BreedsViewModelTests.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 20/10/25.
//

import Testing
import Observation
import SwiftData
@testable import Cats_App

@MainActor
@Suite("BreedsViewModelTests")
struct BreedsViewModelTests {
    var context: ModelContext!
    var mockDataSource: MockBreedsDataSource!
    var sut: BreedsView.DefaultViewModel!

    init() {
        mockDataSource = MockBreedsDataSource()
        let container = try! ModelContainer(for: CatBreed.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
        sut = BreedsView.DefaultViewModel(
            breedsDataSource: mockDataSource,
            toggleFavouriteUseCase: .init(modelContext: context)
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
            var values: [BreedsView.ViewState] = []
            func append(_ state: BreedsView.ViewState) { values.append(state) }
            func snapshot() -> [BreedsView.ViewState] { values }
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
        let expectedStates: [BreedsView.ViewState] = [
            .loadingFirstPage,
            .loaded(properties: .init(isReload: true, hasMore: true, hasConnection: true, dataSourceMode: .online)),
            .loadingMore,
            .loaded(properties: .init(isReload: false, hasMore: false, hasConnection: true, dataSourceMode: .online))
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

        #expect(sut.viewState == .loaded(properties: .init(isReload: true, hasMore: true, hasConnection: true, dataSourceMode: .online)))
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
            #expect(sut.viewState == .loaded(properties: .init(hasMore: true, hasConnection: false, dataSourceMode: .online)))
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
        #expect(sut.viewState == .loaded(properties: .init(isReload: false, hasMore: false, hasConnection: true, dataSourceMode: .online)))
    }

    @Test
    func testToggleFavourite() throws {
        let cat = CatBreed(CatBreedDTO(id: "1", name: "Cat"))
        #expect((cat.isFavourited ?? false) == false)
        try sut.toggleFavourite(for: cat)
        #expect(cat.isFavourited == true)
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
        #expect(sut.viewState == .loaded(properties: .init(isReload: true, hasMore: false, hasConnection: true, dataSourceMode: .online)))
    }

    @Test
    func testLoadFirstPageNetworkErrorSetsHasConnectionFalse() async {
        mockDataSource.shouldThrowNetworkError = true

        do {
            try await sut.loadFirstPage()
            Issue.record("Expected network error not thrown")
        } catch {
            #expect(sut.viewState == .loaded(properties: .init(hasMore: true, hasConnection: false, dataSourceMode: .online)))
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

extension BreedsViewModelTests {
    final class MockBreedsDataSource: BreedsDataSource {
        var pageToReturn: Page<CatBreed>?
        var pageQueue: [Page<CatBreed>] = []
        var shouldThrowNetworkError = false
        var shouldDelay = false
        private(set) var loadNextPageCallCount = 0

        func loadInitialPage(query: String?, mode: DataSourceMode) async throws -> Page<CatBreed>? {
            if shouldThrowNetworkError { throw NetworkError.server(statusCode: 500, message: "") }
            if shouldDelay {
                try? await Task.sleep(for: .seconds(0.5))
            }
            if !pageQueue.isEmpty {
                return pageQueue.removeFirst()
            } else {
                return pageToReturn
            }
        }

        func loadNextPage() async throws -> Page<CatBreed>? {
            if shouldThrowNetworkError { throw NetworkError.server(statusCode: 500, message: "") }
            loadNextPageCallCount += 1
            if shouldDelay {
                try? await Task.sleep(for: .seconds(0.5))
            }
            if !pageQueue.isEmpty {
                return pageQueue.removeFirst()
            } else {
                return pageToReturn
            }
        }
    }
}

