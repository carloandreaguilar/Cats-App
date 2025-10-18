//
//  AllBreedsViewModel.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Observation

extension AllBreedsView {
    
    enum ViewState: Equatable {
        case loadingFirstPage, loadingMore, loaded(hasMore: Bool, dataSourceType: DataSourceType?), error
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
        
        init(breedsDataSource: BreedsDataSource) {
            self.breedsDataSource = breedsDataSource
        }
        
        func loadFirstPage() async {
            do {
                viewState = .loadingFirstPage
                let page = try await breedsDataSource.loadInitialPage()
                updateData(from: page)
            } catch {
                viewState = .error
            }
        }
        
        func loadNextPageIfNeeded() async {
            guard case .loaded(hasMore: true, dataSourceType: _) = viewState else { return }
            do {
                viewState = .loadingMore
                let page = try await breedsDataSource.loadNextPage()
                updateData(from: page)
            } catch {
                viewState = .error
            }
        }
        
        private func updateData(from page: Page<CatBreed>?) {
            if let page = page {
                if page.page == 1 {
                    breeds = page.items
                } else {
                    breeds.append(contentsOf: page.items)
                }
                viewState = .loaded(hasMore: page.hasMore, dataSourceType: page.dataSourceType)
            } else {
                viewState = .loaded(hasMore: false, dataSourceType: nil)
            }
        }
    }
}
