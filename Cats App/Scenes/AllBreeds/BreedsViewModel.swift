//
//  BreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Observation

extension BreedsView {
    
    protocol ViewModel {
        var query: String { get set }
        var viewState: ViewState { get }
        var breeds: [CatBreed] { get }
        func loadFirstPage() async throws
        func loadNextPageIfNeeded() async
        func activateOfflineMode() async throws
        func attemptNetworkRefresh() async throws
        func toggleFavourite(for breed: CatBreed) throws
    }
    
    @Observable
    class DefaultViewModel: ViewModel {
        var query: String = ""
        private let breedsDataSource: BreedsDataSource
        private let toggleFavouriteUseCase: ToggleFavouriteUseCase
        private(set) var viewState: ViewState = .loadingFirstPage
        private(set) var breeds: [CatBreed] = []
        private var hasMore = true
        private var hasConnection = true
        private var currentDataMode: DataSourceMode = .online
        
        init(breedsDataSource: BreedsDataSource, toggleFavouriteUseCase: ToggleFavouriteUseCase) {
            self.breedsDataSource = breedsDataSource
            self.toggleFavouriteUseCase = toggleFavouriteUseCase
        }
        
        func loadFirstPage() async throws {
            viewState = .loadingFirstPage
            do {
                switch currentDataMode {
                case .online:
                    try await loadFirstPage(mode: .online)
                case .offline:
                    try await loadFirstPage(mode: .offline)
                }
            } catch {
                viewState = .loaded(properties: .init(hasMore: hasMore, hasConnection: hasConnection, dataSourceMode: currentDataMode))
                throw error
            }
        }
        
        func loadNextPageIfNeeded() async {
            guard case .loaded(let properties) = viewState, properties.hasMore else { return }
            do {
                viewState = .loadingMore
                let page = try await breedsDataSource.loadNextPage()
                updateData(from: page)
            } catch {
                if error is NetworkError {
                    hasConnection = false
                    viewState = .loaded(properties: .init(hasMore: hasMore, hasConnection: hasConnection, dataSourceMode: currentDataMode))
                }
            }
        }
        
        func activateOfflineMode() async throws {
            currentDataMode = .offline
            try await loadFirstPage(mode: .offline)
        }
        
        func attemptNetworkRefresh() async throws {
            do {
                let page = try await breedsDataSource.loadInitialPage(query: query, mode: .online)
                updateData(from: page)
            } catch {
                hasConnection = false
                viewState = .loaded(properties: .init(hasMore: true, hasConnection: false, dataSourceMode: currentDataMode))
                throw error
            }
        }
        
        func toggleFavourite(for breed: CatBreed) throws {
            try toggleFavouriteUseCase.toggle(for: breed)
        }
        
        private func loadFirstPage(mode: DataSourceMode) async throws {
            do {
                let page = try await breedsDataSource.loadInitialPage(query: query, mode: mode)
                updateData(from: page)
            } catch {
                if error is NetworkError {
                    hasConnection = false
                }
                throw error
            }
        }
        
        private func updateData(from page: Page<CatBreed>?) {
            if let page = page {
                if page.page == 0 {
                    breeds = page.items
                } else {
                    breeds.append(contentsOf: page.items)
                }
                if page.dataSourceMode == .online {
                    hasConnection = true
                }
                hasMore = page.hasMore
                currentDataMode = page.dataSourceMode
                viewState = .loaded(properties: .init(isReload: page.page == 0, hasMore: page.hasMore, hasConnection: hasConnection, dataSourceMode: page.dataSourceMode))
            } else {
                hasMore = false
                viewState = .loaded(properties: .init(hasMore: hasMore, hasConnection: hasConnection, dataSourceMode: currentDataMode))
            }
        }
    }
}

extension BreedsView {
    enum ViewState: Equatable {
        case loadingFirstPage,
             loadingMore,
             loaded(properties: Properties)
        
        struct Properties: Equatable {
            init(isReload: Bool = false, hasMore: Bool, hasConnection: Bool, dataSourceMode: DataSourceMode) {
                self.isReload = isReload
                self.hasMore = hasMore
                self.hasConnection = hasConnection
                self.dataSourceMode = dataSourceMode
            }
            let isReload: Bool
            let hasMore: Bool
            let hasConnection: Bool
            let dataSourceMode: DataSourceMode
        }
    }
}
