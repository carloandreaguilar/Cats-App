//
//  ToggleFavouriteUseCase.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 18/10/25.
//

import SwiftData

enum ToggleFavouriteUseCase {
    static func toggle(for breed: CatBreed, on context: ModelContext) throws {
        breed.isFavourited = !(breed.isFavourited ?? false)
        try context.save()
    }
}
