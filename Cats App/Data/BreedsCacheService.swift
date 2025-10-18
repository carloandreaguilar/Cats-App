//
//  BreedsCacheService.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation
import SwiftData

@MainActor
protocol BreedsCacheService {
    func fetchCachedBreeds(page: Int, pageSize: Int) throws -> [CatBreed]
    func update(_ breeds: [CatBreed]) throws
}

class DefaultBreedsCacheService: BreedsCacheService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchCachedBreeds(page: Int, pageSize: Int) throws -> [CatBreed] {
        var descriptor: FetchDescriptor<CatBreed>
        descriptor = FetchDescriptor<CatBreed>(
            sortBy: [SortDescriptor(\.name)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = max(page - 1, 0) * pageSize
        return try modelContext.fetch(descriptor)
    }
    
    func update(_ breeds: [CatBreed]) throws {
        try self.pruneOldCache(olderThanDays: 3)
        
        for newBreed in breeds {
            let id = newBreed.id
            let descriptor = FetchDescriptor<CatBreed>(
                predicate: #Predicate { $0.id == id }
            )
            let existing = try modelContext.fetch(descriptor).first
            
            if let existing {
                // Update existing fields from the existing object
                existing.update(from: newBreed)
            } else {
                // Insert new
                newBreed.cachedAt = .now
                modelContext.insert(newBreed)
            }
        }
        try modelContext.save()
    }
    
    private func pruneOldCache(olderThanDays: Int) throws {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: .now) else { return }
        let cutoffDate = cutoff
        let descriptor = FetchDescriptor<CatBreed>(
            predicate: #Predicate { breed in
                if let cachedAt = breed.cachedAt {
                    return cachedAt < cutoffDate
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

