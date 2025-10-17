//
//  RestNetworkClient.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//


import Foundation

struct RestNetworkClient {
    let session: URLSession
    let baseURL: URL
    let decoder: JSONDecoder
    
    init(session: URLSession = .shared, baseURL: URL, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.baseURL = baseURL
        self.decoder = decoder
    }
    
    func request<T: Decodable>(_ request: URLRequest) async throws -> T {
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
    
    func makeURL(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + path
            components.queryItems = queryItems?.isEmpty == false ? queryItems : nil

            guard let url = components.url else {
                throw NetworkError.network(underlying: URLError(.badURL))
            }
            return url
        }
}
