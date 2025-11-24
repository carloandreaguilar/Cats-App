//
//  BreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Observation
import SwiftUI

enum BreedsViewState: Equatable {
    case loadingFirstPage,
         loaded(properties: Properties)
    
    struct Properties: Equatable {
        init(hasMore: Bool,
             loadingMore: Bool = false,
             scrollViewId: UUID
        ) {
            self.hasMore = hasMore
            self.loadingMore = loadingMore
            self.scrollViewId = scrollViewId
        }
        let hasMore: Bool
        let loadingMore: Bool
        let scrollViewId: UUID
    }
}

protocol BreedsViewModel {
    var query: String { get set }
    var viewState: BreedsViewState { get }
    var breeds: [CatBreed] { get }
    var navigationPath: Binding<NavigationPath> { get set }
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
    private var scrollViewId = UUID()
    
    var query: String = ""
    var hasConnection = true
    var presentingOfflineAlert = false
    var showingReconnectedToast = false
    var animatingOfflineBanner = false
    var dataSourceMode: DataSourceMode = .online
    var navigationPath: Binding<NavigationPath>
    
    init(breedsDataSource: BreedsDataSource, toggleFavouriteUseCase: ToggleFavouriteUseCase, navigationPath: Binding<NavigationPath>) {
        self.breedsDataSource = breedsDataSource
        self.toggleFavouriteUseCase = toggleFavouriteUseCase
        self.navigationPath = navigationPath
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
            viewState = .loaded(properties: .init(hasMore: hasMore, loadingMore: false, scrollViewId: scrollViewId))
            throw error
        }
    }
    
    func loadNextPageIfNeeded() async {
        guard case .loaded(let properties) = viewState, properties.hasMore else { return }
        do {
            viewState = .loaded(properties: .init(hasMore: hasMore, loadingMore: true, scrollViewId: scrollViewId))
            let page = try await breedsDataSource.loadNextPage()
            updateData(from: page)
        } catch {
            if error is NetworkError {
                hasConnection = false
                viewState = .loaded(properties: .init(hasMore: hasMore, scrollViewId: scrollViewId))
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
            viewState = .loaded(properties: .init(hasMore: true, scrollViewId: scrollViewId))
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
            if page.page == 1 {
                scrollViewId = UUID()
                breeds = page.items
            } else {
                breeds.append(contentsOf: page.items)
            }
            if page.dataSourceMode == .online {
                hasConnection = true
            }
            hasMore = page.hasMore
            dataSourceMode = page.dataSourceMode
            viewState = .loaded(properties: .init(hasMore: page.hasMore, scrollViewId: scrollViewId))
        } else {
            hasMore = false
            viewState = .loaded(properties: .init(hasMore: hasMore, scrollViewId: scrollViewId))
        }
    }
}

