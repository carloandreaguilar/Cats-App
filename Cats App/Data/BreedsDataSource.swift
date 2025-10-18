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
    private let cacheService: BreedsCacheService
    private let networkClient: BreedsNetworkClient
    private let pageSize: Int
    private var currentPage = 1
    private var currentTask: Task<Page<CatBreed>?, Error>? = nil
    
    init(cacheService: BreedsCacheService, networkClient: BreedsNetworkClient, pageSize: Int = AppConstants.defaultPageSize) {
        self.cacheService = cacheService
        self.networkClient = networkClient
        self.pageSize = pageSize
    }
    
    func loadInitialPage() async throws -> Page<CatBreed>? {
        currentPage = 1
        do {
            return try await loadPageFromNetwork(page: currentPage)
        } catch {
            if error is CancellationError { throw error }
            return try await loadPageFromCache(page: currentPage)
        }
    }
    
    /// Assuming the order in which items are sorted (by name) is the same from both sources. If that ever changes this needs to be adjusted.
    func loadNextPage() async throws -> Page<CatBreed>? {
        let nextPage = currentPage + 1
        do {
            return try await self.loadPageFromNetwork(page: nextPage)
        } catch {
            return try await loadPageFromCache(page: nextPage)
        }
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
            
            try cacheService.update(newBreeds)
            
            let newPage = Page(items: newBreeds, page: page, hasMore: newBreeds.count >= pageSize, dataSourceType: .online)
            currentPage = page
            return newPage
        }
        currentTask = newTask
        return try await newTask.value
    }
    
    private func loadPageFromCache(page: Int) async throws -> Page<CatBreed>? {
        currentTask?.cancel()
        let newTask = Task<Page<CatBreed>?, Error> { [weak self] in
            guard let self else { return nil }
            let breeds = try cacheService.fetchCachedBreeds(page: page, pageSize: pageSize)
            
            guard !Task.isCancelled else {
                throw CancellationError()
            }
            
            guard !breeds.isEmpty else {
                return nil
            }
            
            let newPage = Page(items: breeds, page: page, hasMore: breeds.count >= pageSize, dataSourceType: .offline)
            currentPage = page
            return newPage
        }
        currentTask = newTask
        return try await newTask.value
    }
}
