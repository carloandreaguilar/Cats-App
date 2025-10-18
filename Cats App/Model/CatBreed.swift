//
//  CatBreed.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftData
import Foundation

@Model
final class CatBreed {
    @Attribute(.unique) var id: String
    var name: String
    var origin: String?
    var descriptionText: String?
    var temperament: String?
    var maxLifespan: Int?
    var imageURL: URL?
    
    var cachedAt: Date?
    
    init(_ dto: CatBreedDTO) {
        self.id = dto.id
        self.name = dto.name
        self.origin = dto.origin
        self.descriptionText = dto.descriptionText
        self.temperament = dto.temperament
        self.maxLifespan = dto.maxLifespan
        self.imageURL = dto.imageURL
        self.cachedAt = .now
    }
    
    func update(from updatedBreed: CatBreed) {
        self.name = updatedBreed.name
        self.origin = updatedBreed.origin
        self.descriptionText = updatedBreed.descriptionText
        self.temperament = updatedBreed.temperament
        self.maxLifespan = updatedBreed.maxLifespan
        self.imageURL = updatedBreed.imageURL
        self.cachedAt = .now
    }
}

