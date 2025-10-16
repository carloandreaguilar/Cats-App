//
//  CatBreed.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftData

@Model
final class CatBreed {
    @Attribute(.unique) var id: String
    var name: String
    var origin: String?
    var descriptionText: String?
    var temperament: String?
    var lifeSpan: String?
    var wikipediaURL: String?
    var weightMetric: String?
    
    init(
        id: String,
        name: String,
        origin: String? = nil,
        descriptionText: String? = nil,
        temperament: String? = nil,
        lifeSpan: String? = nil,
        wikipediaURL: String? = nil,
        weightMetric: String? = nil,
        weightImperial: String? = nil
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.descriptionText = descriptionText
        self.temperament = temperament
        self.lifeSpan = lifeSpan
        self.wikipediaURL = wikipediaURL
        self.weightMetric = weightMetric
    }
}
