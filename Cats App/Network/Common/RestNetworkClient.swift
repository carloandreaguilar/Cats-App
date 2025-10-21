//
//  RestNetworkClient.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//


import Foundation

protocol RestNetworkClient {
    func request<T: Decodable>(_ request: URLRequest) async throws -> T
    func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL
}

struct DefaultRestNetworkClient: RestNetworkClient {
    let session: URLSession
    let baseURL: URL
    let decoder: JSONDecoder
    
    init(session: URLSession = .shared, baseURL: URL, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.baseURL = baseURL
        self.decoder = decoder
    }
    
    func request<T: Decodable>(_ request: URLRequest) async throws -> T {
        #if DEBUG
        try simulateOfflineIfNeeded()
        #endif
        
        do {
            try Task.checkCancellation()
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let httpUrlResponse = response as? HTTPURLResponse else { throw NetworkError.network(underlying: URLError(.badServerResponse)) }
            guard (200..<300).contains(httpUrlResponse.statusCode) else {
                throw NetworkError.server(statusCode: httpUrlResponse.statusCode, message: nil)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decoding(underlying: error)
            }
        } catch {
            if let networkError = error as? NetworkError { throw networkError }
            throw NetworkError.network(underlying: error)
        }
    }
    
    func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.path = baseURL.path + path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw NetworkError.network(underlying: URLError(.badURL))
        }
        return url
    }
}

extension DefaultRestNetworkClient {
    private func simulateOfflineIfNeeded() throws {
        if CommandLine.arguments.contains("--simulateOffline") {
            throw NetworkError.network(underlying: URLError(.notConnectedToInternet))
        }
    }
}
