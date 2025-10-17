//
//  BreedsNetworkClient.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation

protocol BreedsNetworkClient {
    func fetchBreeds(page: Int, pageSize: Int) async throws -> [CatBreedDTO]
}

class DefaultBreedsNetworkClient: BreedsNetworkClient {
    static let defaultBaseURL = URL(string: "https://api.thecatapi.com/v1")!
    static let defaultApiKey = "live_7RYf9Kx3GFcrGzFd6UVh9yGHAbgIrivdcn9ZaI6aaKXq53jLvS1CUaReccSqNHgs"
    private let networkClient: RestNetworkClient
    private let apiKey: String
    
    init(restNetworkClient: RestNetworkClient, apiKey: String) {
        self.networkClient = restNetworkClient
        self.apiKey = apiKey
    }
    
    init() {
        let decoder = JSONDecoder()
        self.networkClient = .init(baseURL: Self.defaultBaseURL, decoder: decoder)
        self.apiKey = Self.defaultApiKey
    }

    
    func fetchBreeds(page: Int = 1, pageSize: Int) async throws -> [CatBreedDTO] {
        let path = "/breeds"
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "page", value: String(page))
        ]
        let url = try networkClient.makeURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setHeaders(on: &request)
        
        return try await networkClient.request(request)
    }
    
    private func setHeaders(on request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    }
}
