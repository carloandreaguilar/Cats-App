//
//  CatBreed.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftData
import Foundation

@Model
final class CatBreed: Decodable {
    @Attribute(.unique) var id: String
    var name: String
    var origin: String?
    var descriptionText: String?
    var temperament: String?
    var lifeSpan: ClosedRange<Int>?
    var imageURL: URL?
    
    init(
        id: String,
        name: String,
        origin: String? = nil,
        descriptionText: String? = nil,
        temperament: String? = nil,
        lifeSpan: ClosedRange<Int>? = nil,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.descriptionText = descriptionText
        self.temperament = temperament
        self.lifeSpan = lifeSpan
        self.imageURL = imageURL
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case origin
        case descriptionText = "description"
        case temperament
        case lifeSpan = "life_span"
        case image
    }
    
    private enum ImageCodingKeys: String, CodingKey {
        case url
    }
    
    private static func parseLifeSpanRange(_ text: String) -> ClosedRange<Int>? {
        let values = text
            .split(separator: "-")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { Int($0) }
            .sorted()
        guard !values.isEmpty else { return nil }
        return values.first!...values.last!
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let origin = try container.decodeIfPresent(String.self, forKey: .origin)
        let descriptionText = try container.decodeIfPresent(String.self, forKey: .descriptionText)
        let temperament = try container.decodeIfPresent(String.self, forKey: .temperament)
        let lifeSpanRange: ClosedRange<Int>? = try {
            guard let lifeSpanString = try container.decodeIfPresent(String.self, forKey: .lifeSpan) else {
                return nil
            }
            return Self.parseLifeSpanRange(lifeSpanString)
        }()
        let imageUrl: URL? = try {
            if container.contains(.image) {
                let imageContainer = try container.nestedContainer(keyedBy: ImageCodingKeys.self, forKey: .image)
                return try imageContainer.decodeIfPresent(URL.self, forKey: .url)
            }
            return nil
        }()
        self.init(
            id: id,
            name: name,
            origin: origin,
            descriptionText: descriptionText,
            temperament: temperament,
            lifeSpan: lifeSpanRange,
            imageURL: imageUrl
        )
    }
}

