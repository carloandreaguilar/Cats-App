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
    private let networkService: BreedsNetworkService
    private let persistenceService: BreedsPersistenceService
    private let pageSize: Int
    private var currentPage = 1
    private var currentTask: Task<Page<CatBreed>?, Error>? = nil
    
    init(networkService: BreedsNetworkService, persistenceService: BreedsPersistenceService, pageSize: Int = AppConstants.defaultPageSize) {
        self.networkService = networkService
        self.persistenceService = persistenceService
        self.pageSize = pageSize
    }
    
    func loadInitialPage() async throws -> Page<CatBreed>? {
        currentPage = 1
        do {
            return try await loadPageFromNetwork(page: currentPage)
        } catch {
            if error is CancellationError { throw error }
            return try await loadPageFromPersistence(page: currentPage)
        }
    }
    
    /// Assuming the order in which items are sorted (by name) is the same from both sources. If that ever changes this needs to be adjusted.
    func loadNextPage() async throws -> Page<CatBreed>? {
        let nextPage = currentPage + 1
        do {
            return try await self.loadPageFromNetwork(page: nextPage)
        } catch {
            return try await loadPageFromPersistence(page: nextPage)
        }
    }
    
    private func loadPageFromNetwork(page: Int) async throws -> Page<CatBreed>? {
        currentTask?.cancel()
        let newTask = Task<Page<CatBreed>?, Error> { [weak self] in
            guard let self else { throw NSError() }
            
            let newBreedDtos = try await networkService.fetchBreeds(page: page, pageSize: pageSize)
            
            guard !Task.isCancelled else {
                throw CancellationError()
            }
            
            guard !newBreedDtos.isEmpty else {
                return nil
            }
            
            let newBreeds = try persistenceService.persist(newBreedDtos)
            
            let newPage = Page(items: newBreeds, page: page, hasMore: newBreeds.count >= pageSize, dataSourceType: .online)
            currentPage = page
            return newPage
        }
        currentTask = newTask
        return try await newTask.value
    }
    
    private func loadPageFromPersistence(page: Int) async throws -> Page<CatBreed>? {
        currentTask?.cancel()
        let newTask = Task<Page<CatBreed>?, Error> { [weak self] in
            guard let self else { return nil }
            let breeds = try persistenceService.fetchPersistedBreeds(page: page, pageSize: pageSize)
            
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
