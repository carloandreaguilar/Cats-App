//
//  MockRestNetworkClient.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 21/10/25.
//

import Foundation
@testable import Cats_App

final class MockRestNetworkClient: RestNetworkClient {
    let baseURL: URL
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    var requestHandler: ((URLRequest) async throws -> Any)?
    
    func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }
    
    func request<T: Decodable>(_ request: URLRequest) async throws -> T {
        guard let handler = requestHandler else {
            fatalError("requestHandler must be set before calling request(_:)")
        }
        let result = try await handler(request)
        guard let typedResult = result as? T else {
            fatalError("requestHandler returned incorrect type. Expected \(T.self), got \(type(of: result))")
        }
        return typedResult
    }
}
