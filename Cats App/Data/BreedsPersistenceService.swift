//
//  BreedsPersistenceService.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation
import SwiftData

protocol BreedsPersistenceService {
    func fetchPersistedBreeds(query: String?, page: Int, pageSize: Int) throws -> [CatBreed]
    func persist(_ breedDtos: [CatBreedDTO]) throws -> [CatBreed]
}

class DefaultBreedsPersistenceService: BreedsPersistenceService {
    private let modelContext: ModelContext
    private let daysToKeepDataFor: Int
    
    init(modelContext: ModelContext, daysToKeepDataFor: Int = 30) {
        self.modelContext = modelContext
        self.daysToKeepDataFor = daysToKeepDataFor
    }
    
    func fetchPersistedBreeds(query: String?, page: Int, pageSize: Int) throws -> [CatBreed] {
        var descriptor: FetchDescriptor<CatBreed>
        let query = query?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let query, !query.isEmpty {
            descriptor = FetchDescriptor<CatBreed>(
                predicate: #Predicate { breed in
                    breed.name.localizedStandardContains(query)
                },
                sortBy: [SortDescriptor(\.name)]
            )
        } else {
            descriptor = FetchDescriptor<CatBreed>(
                sortBy: [SortDescriptor(\.name)]
            )
        }
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = max(page - 1, 0) * pageSize
        return try modelContext.fetch(descriptor)
    }
    
    func persist(_ breedDtos: [CatBreedDTO]) throws -> [CatBreed] {
        guard !breedDtos.isEmpty else { return [] }
        try pruneOldData()

        let breedDtoIds = breedDtos.map(\.id)
        let descriptor = FetchDescriptor<CatBreed>(
            predicate: #Predicate { breedDtoIds.contains($0.id) }
        )
        let existingBreeds = try modelContext.fetch(descriptor)
        let breedById = Dictionary(uniqueKeysWithValues: existingBreeds.map { ($0.id, $0) })

        var persistedBreeds = [CatBreed]()
        
        for dto in breedDtos {
            if let existing = breedById[dto.id] {
                existing.update(from: dto)
                persistedBreeds.append(existing)
            } else {
                let newBreed = CatBreed(dto)
                modelContext.insert(newBreed)
                persistedBreeds.append(newBreed)
            }
        }

        try modelContext.save()
        return persistedBreeds
    }
    
    private func pruneOldData() throws {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -daysToKeepDataFor, to: .now) else { return }
        let cutoffDate = cutoff
        let batchSize = 1000
        var itemsToDelete = [CatBreed]()
        repeat {
            var descriptor = FetchDescriptor<CatBreed>(
                predicate: #Predicate { breed in
                    if let persistedAt = breed.persistedAt {
                        return persistedAt < cutoffDate
                    } else {
                        return true
                    }
                }
            )
            descriptor.fetchLimit = batchSize
            itemsToDelete = try modelContext.fetch(descriptor)
            if itemsToDelete.isEmpty { break }
            for item in itemsToDelete { modelContext.delete(item) }
            try modelContext.save()
        } while !itemsToDelete.isEmpty
    }
}
