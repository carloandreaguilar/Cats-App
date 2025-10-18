//
//  ToggleFavouriteUseCase.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 18/10/25.
//

import SwiftData

struct ToggleFavouriteUseCase {
    let modelContext: ModelContext
    
    func toggle(for breed: CatBreed) throws {
        breed.isFavourited = !(breed.isFavourited ?? false)
        try modelContext.save()
    }
}
