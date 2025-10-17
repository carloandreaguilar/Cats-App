//
//  BreedsDataSource.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation

protocol BreedsDataSource {
    func loadInitialPage() async throws -> Page<CatBreed>?
    func loadNextPage() async throws -> Page<CatBreed>?
}

class DefaultBreedsDataSource: BreedsDataSource {
    static let defaultPageSize = 12
    private let networkClient: BreedsNetworkClient
    private let pageSize: Int
    private var currentPage = 1
    private var currentTask: Task<Page<CatBreed>?, Error>? = nil
    
    init(networkClient: BreedsNetworkClient = DefaultBreedsNetworkClient(), pageSize: Int) {
        self.networkClient = networkClient
        self.pageSize = pageSize
    }
    
    convenience init() {
        self.init(pageSize: Self.defaultPageSize)
    }
    
    func loadInitialPage() async throws -> Page<CatBreed>? {
        currentPage = 1
        return try await loadPageFromNetwork(page: currentPage)
    }
    
    func loadNextPage() async throws -> Page<CatBreed>? {
        return try await loadPageFromNetwork(page: currentPage + 1)
    }
    
    private func loadPageFromNetwork(page: Int) async throws -> Page<CatBreed>? {
        currentTask?.cancel()
        let newTask = Task<Page<CatBreed>?, Error> { [weak self] in
            guard let self else { throw NSError() }
           
            let newBreeds = try await networkClient.fetchBreeds(page: page, pageSize: pageSize).map { CatBreed($0) }
            
            guard !Task.isCancelled else {
                throw CancellationError()
            }
            
            guard !newBreeds.isEmpty else {
                return nil
            }

            let newPage = Page(items: newBreeds, page: page, hasMore: newBreeds.count >= pageSize)
            currentPage = page
            return newPage
        }
        currentTask = newTask
        return try await newTask.value
    }
}
