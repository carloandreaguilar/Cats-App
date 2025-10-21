//
//  MockBreedsDataSource.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 21/10/25.
//

import Foundation
import SwiftData
@testable import Cats_App

final class MockBreedsDataSource: BreedsDataSource {
    var pageToReturn: Page<CatBreed>?
    var pageQueue: [Page<CatBreed>] = []
    var shouldThrowNetworkError = false
    var shouldDelay = false
    private(set) var loadNextPageCallCount = 0
    
    func loadInitialPage(query: String?, mode: DataSourceMode) async throws -> Page<CatBreed>? {
        if shouldThrowNetworkError { throw NetworkError.network(underlying: URLError(.notConnectedToInternet)) }
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
        if shouldThrowNetworkError { throw NetworkError.network(underlying: URLError(.notConnectedToInternet)) }
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
