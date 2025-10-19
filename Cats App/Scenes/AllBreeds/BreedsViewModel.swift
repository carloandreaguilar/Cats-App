//
//  BreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Observation

extension BreedsView {
    
    enum ViewState: Equatable {
        case loadingFirstPage,
             loadingMore,
             loaded(hasMore: Bool, hasConnection: Bool, dataSourceMode: DataSourceMode)
    }
    
    protocol ViewModel {
        var query: String { get set }
        var viewState: ViewState { get }
        var breeds: [CatBreed] { get }
        func loadFirstPage() async throws
        func loadNextPageIfNeeded() async
        func activateOfflineMode() async throws
        func attemptReconnect() async throws
        func toggleFavourite(for breed: CatBreed) throws
    }
    
    @Observable
    class DefaultViewModel: ViewModel {
        var query: String = ""
        private let breedsDataSource: BreedsDataSource
        private let toggleFavouriteUseCase: ToggleFavouriteUseCase
        private(set) var viewState: ViewState = .loadingFirstPage
        private(set) var breeds: [CatBreed] = []
        private var hasConnection = true
        private var currentDataMode: DataSourceMode = .online
        
        init(breedsDataSource: BreedsDataSource, toggleFavouriteUseCase: ToggleFavouriteUseCase) {
            self.breedsDataSource = breedsDataSource
            self.toggleFavouriteUseCase = toggleFavouriteUseCase
        }
        
        func loadFirstPage() async throws {
            viewState = .loadingFirstPage
            do {
                try await loadFirstPage(mode: .online)
            } catch {
                do {
                    try await loadFirstPage(mode: .offline)
                } catch {
                    viewState = .loaded(hasMore: false, hasConnection: hasConnection, dataSourceMode: currentDataMode)
                    throw error
                }
            }
        }
        
        func loadNextPageIfNeeded() async {
            guard case .loaded(hasMore: true, hasConnection: _, dataSourceMode: _) = viewState else { return }
            do {
                viewState = .loadingMore
                let page = try await breedsDataSource.loadNextPage()
                updateData(from: page)
            } catch {
                if error is NetworkError {
                    hasConnection = false
                    viewState = .loaded(hasMore: true, hasConnection: hasConnection, dataSourceMode: currentDataMode)
                }
            }
        }
        
        func activateOfflineMode() async throws {
            currentDataMode = .offline
            viewState = .loadingFirstPage
            try await loadFirstPage(mode: .offline)
        }
        
        func attemptReconnect() async throws {
            guard currentDataMode == .offline else { return }
            do {
                let page = try await breedsDataSource.loadInitialPage(query: query, mode: .online)
                updateData(from: page)
            } catch {
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
                currentDataMode = page.dataSourceMode
                viewState = .loaded(hasMore: page.hasMore, hasConnection: hasConnection, dataSourceMode: page.dataSourceMode)
            } else {
                viewState = .loaded(hasMore: false, hasConnection: hasConnection, dataSourceMode: currentDataMode)
            }
        }
    }
}
