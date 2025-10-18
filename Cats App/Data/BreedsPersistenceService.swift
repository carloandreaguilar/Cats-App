//
//  BreedsPersistenceService.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation
import SwiftData

protocol BreedsPersistenceService {
    func fetchPersistedBreeds(page: Int, pageSize: Int) throws -> [CatBreed]
    func persist(_ breedDtos: [CatBreedDTO]) throws -> [CatBreed]
}

class DefaultBreedsPersistenceService: BreedsPersistenceService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchPersistedBreeds(page: Int, pageSize: Int) throws -> [CatBreed] {
        var descriptor: FetchDescriptor<CatBreed>
        descriptor = FetchDescriptor<CatBreed>(
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = max(page - 1, 0) * pageSize
        return try modelContext.fetch(descriptor)
    }
    
    func persist(_ breedDtos: [CatBreedDTO]) throws -> [CatBreed] {
        guard !breedDtos.isEmpty else { return [] }
        try self.pruneOldPersistence(olderThanDays: 3)
        
        var newBreeds = [CatBreed]()
        for dto in breedDtos {
            if let existing = try fetchBreed(id: dto.id) {
                existing.update(from: dto)
                newBreeds.append(existing)
            } else {
                newBreeds.append(CatBreed(dto))
            }
        }
        
        try modelContext.save()
        
        return newBreeds
    }
    
    func fetchBreed(id: String) throws -> CatBreed? {
        let descriptor = FetchDescriptor<CatBreed>(
            predicate: #Predicate { $0.id == id }
        )
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    private func pruneOldPersistence(olderThanDays: Int) throws {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: .now) else { return }
        let cutoffDate = cutoff
        let descriptor = FetchDescriptor<CatBreed>(
            predicate: #Predicate { breed in
                if let persistedAt = breed.persistedAt {
                    return persistedAt < cutoffDate
                } else {
                    return true
                }
            }
        )
        let old = try modelContext.fetch(descriptor)
        for item in old { modelContext.delete(item) }
        try modelContext.save()
    }
}

