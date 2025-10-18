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
    
    init(
        id: String,
        name: String,
        origin: String? = nil,
        descriptionText: String? = nil,
        temperament: String? = nil,
        maxLifespan: Int? = nil,
        imageURL: URL? = nil,
        isFavourited: Bool? = nil,
        persistedAt: Date? = .now
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.descriptionText = descriptionText
        self.temperament = temperament
        self.maxLifespan = maxLifespan
        self.imageURL = imageURL
        self.isFavourited = isFavourited
        self.persistedAt = persistedAt
    }
    
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

extension CatBreed {
    static var example: CatBreed {
        return CatBreed(
            id: "example-id",
            name: "Abyssinian",
            origin: "Ethiopia",
            descriptionText: "Active, intelligent, and playful.",
            temperament: "Affectionate, Energetic",
            maxLifespan: 15,
            imageURL: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQGVkW-A9_HBI0o3gYv7K45Usa53Kfydi8JjMpp2n-si_4Gvfm8FvK828zBC0ZCsl_Uo5v-Vg"),
            isFavourited: false,
            persistedAt: .now
        )
    }
}

