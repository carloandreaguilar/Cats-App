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
    
    var isFavourited: Bool?
    var persistedAt: Date?
    
    init(_ dto: CatBreedDTO) {
        self.id = dto.id
        self.name = dto.name
        self.origin = dto.origin
        self.descriptionText = dto.descriptionText
        self.temperament = dto.temperament
        self.maxLifespan = dto.maxLifespan
        self.imageURL = dto.imageURL
        self.persistedAt = .now
    }
    
    func update(from dto: CatBreedDTO) {
        self.name = dto.name
        self.origin = dto.origin
        self.descriptionText = dto.descriptionText
        self.temperament = dto.temperament
        self.maxLifespan = dto.maxLifespan
        self.imageURL = dto.imageURL
        self.persistedAt = .now
    }
}

