//
//  BreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Observation

enum BreedsViewState: Equatable {
    case loadingFirstPage,
         loaded(properties: Properties)
    
    struct Properties: Equatable {
        init(hasMore: Bool,
             loadingMore: Bool = false,
             isReload: Bool = false
        ) {
            self.hasMore = hasMore
            self.loadingMore = loadingMore
            self.isReload = isReload
        }
        let hasMore: Bool
        let loadingMore: Bool
        let isReload: Bool
    }
}

protocol BreedsViewModel {
    var query: String { get set }
    var viewState: BreedsViewState { get }
    var breeds: [CatBreed] { get }
    var hasConnection: Bool { get }
    var presentingOfflineAlert: Bool { get set }
    var showingReconnectedToast: Bool { get set }
    var dataSourceMode: DataSourceMode { get }
    var animatingOfflineBanner: Bool { get set }
    func loadFirstPage() async throws
    func loadNextPageIfNeeded() async
    func activateOfflineMode() async throws
    func attemptNetworkRefresh() async throws
    func toggleFavourite(for breed: CatBreed) throws
}

@Observable
class DefaultBreedsViewModel: BreedsViewModel {
    private let breedsDataSource: BreedsDataSource
    private let toggleFavouriteUseCase: ToggleFavouriteUseCase
    private(set) var viewState: BreedsViewState = .loadingFirstPage
    private(set) var breeds: [CatBreed] = []
    private var hasMore = true
    
    var query: String = ""
    var hasConnection = true
    var presentingOfflineAlert = false
    var showingReconnectedToast = false
    var animatingOfflineBanner = false
    var dataSourceMode: DataSourceMode = .online
    
    init(breedsDataSource: BreedsDataSource, toggleFavouriteUseCase: ToggleFavouriteUseCase) {
        self.breedsDataSource = breedsDataSource
        self.toggleFavouriteUseCase = toggleFavouriteUseCase
    }
    
    func loadFirstPage() async throws {
        viewState = .loadingFirstPage
        do {
            switch dataSourceMode {
            case .online:
                try await loadFirstPage(mode: .online)
            case .offline:
                try await loadFirstPage(mode: .offline)
            }
        } catch {
            viewState = .loaded(properties: .init(hasMore: hasMore, loadingMore: false))
            throw error
        }
    }
    
    func loadNextPageIfNeeded() async {
        guard case .loaded(let properties) = viewState, properties.hasMore else { return }
        do {
            viewState = .loaded(properties: .init(hasMore: hasMore, loadingMore: true))
            let page = try await breedsDataSource.loadNextPage()
            updateData(from: page)
        } catch {
            if error is NetworkError {
                hasConnection = false
                viewState = .loaded(properties: .init(hasMore: hasMore))
            }
        }
    }
    
    func activateOfflineMode() async throws {
        dataSourceMode = .offline
        try await loadFirstPage(mode: .offline)
    }
    
    func attemptNetworkRefresh() async throws {
        let wasOffline = dataSourceMode == .offline
        do {
            let page = try await breedsDataSource.loadInitialPage(query: query, mode: .online)
            if wasOffline {
                showingReconnectedToast = true
            }
            updateData(from: page)
        } catch {
            hasConnection = false
            if wasOffline {
                presentingOfflineAlert = true
            }
            viewState = .loaded(properties: .init(hasMore: true))
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
            let isReload: Bool
            if page.page == 1 {
                isReload = true
                breeds = page.items
            } else {
                isReload = false
                breeds.append(contentsOf: page.items)
            }
            if page.dataSourceMode == .online {
                hasConnection = true
            }
            hasMore = page.hasMore
            dataSourceMode = page.dataSourceMode
            viewState = .loaded(properties: .init(hasMore: page.hasMore, isReload: isReload))
        } else {
            hasMore = false
            viewState = .loaded(properties: .init(hasMore: hasMore))
        }
    }
}

