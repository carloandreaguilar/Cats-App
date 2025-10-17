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
    var lifeSpan: ClosedRange<Int>?
    var imageURL: URL?
    
    init(_ dto: CatBreedDTO) {
        self.id = dto.id
        self.name = dto.name
        self.origin = dto.origin
        self.descriptionText = dto.descriptionText
        self.temperament = dto.temperament
        self.lifeSpan = dto.lifeSpan
        self.imageURL = dto.imageURL
    }
}

