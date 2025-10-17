//
//  AllBreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Observation

extension AllBreedsView {
    
    enum ViewState: Equatable {
        case loadingFirstPage, loadingMore, loaded(hasMore: Bool), error
    }
    
    protocol ViewModel {
        var viewState: ViewState { get }
        var breeds: [CatBreed] { get }
        func loadFirstPage() async
        func loadNextPageIfNeeded() async
    }
    
    @Observable
    class DefaultViewModel: ViewModel {
        private let breedsDataSource: BreedsDataSource
        private(set) var viewState: ViewState = .loadingFirstPage
        private(set) var breeds: [CatBreed] = []
        
        init(breedsDataSource: BreedsDataSource = DefaultBreedsDataSource()) {
            self.breedsDataSource = breedsDataSource
        }
        
        func loadFirstPage() async {
            do {
                viewState = .loadingFirstPage
                if let page = try await breedsDataSource.loadInitialPage() {
                    self.breeds = page.items
                    viewState = .loaded(hasMore: page.hasMore)
                } else {
                    viewState = .loaded(hasMore: false)
                }
            } catch {
                viewState = .error
            }
        }
        
        func loadNextPageIfNeeded() async {
            guard viewState == .loaded(hasMore: true) else { return }
            do {
                viewState = .loadingMore
                if let page = try await breedsDataSource.loadNextPage() {
                    self.breeds.append(contentsOf: page.items)
                    viewState = .loaded(hasMore: page.hasMore)
                } else {
                    viewState = .loaded(hasMore: false)
                }
            } catch {
                viewState = .error
            }
        }
    }
}
