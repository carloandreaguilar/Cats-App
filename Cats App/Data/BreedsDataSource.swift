//
//  BreedsDataSource.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation

protocol BreedsDataSource {
    func loadInitialPage(query: String?, mode: DataSourceMode) async throws -> Page<CatBreed>?
    func loadNextPage() async throws -> Page<CatBreed>?
}

class DefaultBreedsDataSource: BreedsDataSource {
    private let networkService: BreedsNetworkService
    private let persistenceService: BreedsPersistenceService
    private let pageSize: Int
    private var currentPage = 0
    private var currentQuery: String?
    private var currentMode: DataSourceMode = .online
    private var currentTask: Task<Page<CatBreed>?, Error>? = nil
    
    init(networkService: BreedsNetworkService, persistenceService: BreedsPersistenceService, pageSize: Int = AppConstants.defaultPageSize) {
        self.networkService = networkService
        self.persistenceService = persistenceService
        self.pageSize = pageSize
    }
    
    func loadInitialPage(query: String?, mode: DataSourceMode) async throws -> Page<CatBreed>? {
        currentQuery = query
        currentPage = 0
        switch mode {
        case .online:
            return try await loadPageFromNetwork(page: currentPage)
        case .offline:
            return try await loadPageFromPersistence(page: currentPage)
        }
    }
    
    func loadNextPage() async throws -> Page<CatBreed>? {
        let nextPage = currentPage + 1
        switch currentMode {
        case .online:
            return try await loadPageFromNetwork(page: nextPage)
        case .offline:
            return try await loadPageFromPersistence(page: nextPage)
        }
    }
    
    private func loadPageFromNetwork(page: Int) async throws -> Page<CatBreed>? {
        currentTask?.cancel()
        let newTask = Task<Page<CatBreed>?, Error> { [weak self] in
            guard let self else { throw NSError() }
            
            var newBreedDtos = [CatBreedDTO]()
            if let currentQuery, !currentQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                newBreedDtos = try await networkService.searchBreeds(matching: currentQuery, page: page, pageSize: pageSize)
            } else {
                newBreedDtos = try await networkService.fetchBreeds(page: page, pageSize: pageSize)
            }
            
            guard !Task.isCancelled else {
                throw CancellationError()
            }
            
            let newBreeds = try persistenceService.persist(newBreedDtos)
            
            let newPage = Page(items: newBreeds, page: page, hasMore: newBreeds.count >= pageSize, dataSourceMode: .online)
            currentMode = .online
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
            let breeds = try persistenceService.fetchPersistedBreeds(query: currentQuery, page: page, pageSize: pageSize)
            
            guard !Task.isCancelled else {
                throw CancellationError()
            }
            
            let newPage = Page(items: breeds, page: page, hasMore: breeds.count >= pageSize, dataSourceMode: .offline)
            currentMode = .offline
            currentPage = page
            return newPage
        }
        currentTask = newTask
        return try await newTask.value
    }
}
