//
//  BreedsNetworkServiceTests.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 20/10/25.
//

import Foundation
import Testing
@testable import Cats_App

@Suite("BreedsNetworkService")
struct BreedsNetworkServiceTests {
    
    let apiKey = "test-api-key"
    let baseURL = URL(string: "https://thecatapi.com")!
   
    @MainActor
    @Test
    func testFetchBreedsRequestBuilding() async throws {
        let mock = MockRestNetworkClient(baseURL: baseURL)
        let sut = DefaultBreedsNetworkService(restNetworkClient: mock, apiKey: apiKey)
        let expected = [CatBreedDTO(id: "abys", name: "Abyssinian")]
        mock.requestHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "x-api-key") == apiKey)
            #expect(request.httpMethod == "GET")

            let comps = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)!
            #expect(comps.path == "/breeds")
            let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            #expect(items["limit"] == "20")
            /// API is zero indexed.
            #expect(items["page"] == "0")

            return expected
        }
        let result: [CatBreedDTO] = try await sut.fetchBreeds(page: 1, pageSize: 20)
        #expect(result == expected)
    }
   
    @MainActor
    @Test
    func testSearchBreedsRequestBuilding() async throws {
        let mock = MockRestNetworkClient(baseURL: baseURL)
        let sut = DefaultBreedsNetworkService(restNetworkClient: mock, apiKey: apiKey)
        let expected = [CatBreedDTO(id: "siam", name: "Siamese")]
        mock.requestHandler = { request in
            let comps = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)!
            #expect(comps.path == "/breeds/search")
            let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            #expect(items["q"] == "siamese")
            #expect(items["limit"] == "10")
            #expect(items["page"] == "0")
            #expect(request.value(forHTTPHeaderField: "x-api-key") == apiKey)
            return expected
        }
        let result: [CatBreedDTO] = try await sut.searchBreeds(matching: "  siamese  ", pageSize: 10)
        #expect(result == expected)
    }

    @Test("testURLSessionErrorThrowsNetworkError")
    func testFetchBreedsThrowsNetworkError() async {
        let mock = MockRestNetworkClient(baseURL: baseURL)
        let sut = await DefaultBreedsNetworkService(restNetworkClient: mock, apiKey: apiKey)
        mock.requestHandler = { _ in throw DummyError.network }
        await #expect(throws: DummyError.network) {
            let _: [CatBreedDTO] = try await sut.fetchBreeds(page: 0, pageSize: 5)
        }
    }

    @Test
    func testSearchBreedsThrowsNetworkError() async {
        let mock = MockRestNetworkClient(baseURL: baseURL)
        let sut = await DefaultBreedsNetworkService(restNetworkClient: mock, apiKey: apiKey)
        mock.requestHandler = { _ in throw DummyError.network }
        await #expect(throws: DummyError.network) {
            let _: [CatBreedDTO] = try await sut.searchBreeds(matching: "abys", page: 1, pageSize: 5)
        }
    }

    @Test
    func fetchBreedsDefaultsToPage0() async throws {
        let mock = MockRestNetworkClient(baseURL: baseURL)
        let sut = await DefaultBreedsNetworkService(restNetworkClient: mock, apiKey: apiKey)
        mock.requestHandler = { request in
            let comps = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)!
            let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            #expect(items["page"] == "0")
            return [CatBreedDTO]()
        }
        _ = try await sut.fetchBreeds(pageSize: 5)
    }
}

extension BreedsNetworkServiceTests {
    
    enum DummyError: Error, Equatable { case network }
    
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
}

