//
//  BreedsNetworkClient.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation

protocol BreedsNetworkService {
    func fetchBreeds(page: Int, pageSize: Int) async throws -> [CatBreedDTO]
    func searchBreeds(matching query: String, page: Int, pageSize: Int) async throws -> [CatBreedDTO]
}

class DefaultBreedsNetworkService: BreedsNetworkService {
    private let networkClient: RestNetworkClient
    private let apiKey: String
    
    init(restNetworkClient: RestNetworkClient = DefaultRestNetworkClient(baseURL: AppConstants.defaultBaseURL), apiKey: String = AppConstants.defaultApiKey) {
        self.networkClient = restNetworkClient
        self.apiKey = apiKey
    }
    
    func fetchBreeds(page: Int = 1, pageSize: Int) async throws -> [CatBreedDTO] {
        /// API paging is 0 indexed
        let page = max(page - 1, 0)
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
    
    func searchBreeds(matching query: String, page: Int = 1, pageSize: Int) async throws -> [CatBreedDTO] {
        /// API paging is 0 indexed
        let page = max(page - 1, 0)
        let path = "/breeds/search"
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
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

