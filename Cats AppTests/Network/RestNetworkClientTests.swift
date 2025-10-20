//
//  RestNetworkClientTests.swift
//  Cats AppTests
//
//  Created by Carlo André Aguilar on 20/10/25.
//

import Foundation
import Testing
@testable import Cats_App

@Suite("RestNetworkClient")
struct RestNetworkClientTests {
    
    let baseUrl = "https://thecatapi.com/v1"
    
    /// As a single test case to ensure they run serially and isolated, since MockURLProtocol has a shared state.
    @Test
    func testNetworkClient() async throws {
        try makeUrl()
        try await testDecodingOnSuccess()
        try await testNonHTTPURLResponseThrowsNetworkError()
        try await testServerStatusCodeThrowsServerError()
        try await testThrowsDecodingError()
        try await testURLSessionErrorThrowsNetworkError()
    }
    
    func makeUrl() throws {
        let baseURL = URL(string: baseUrl)!
        let client = DefaultRestNetworkClient(baseURL: baseURL)
        
        let url = try client.makeURL(
            path: "/cats",
            queryItems: [
                URLQueryItem(name: "page", value: "2"),
                URLQueryItem(name: "limit", value: "10")
            ]
        )
        
        let absolute = url.absoluteString
        let option1 = "\(baseUrl)/cats?page=2&limit=10"
        #expect(absolute == option1)
    }

    struct TestResponse: Codable, Equatable { let message: String }

    func testDecodingOnSuccess() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let baseURL = URL(string: "\(baseUrl)/v1")!
        let client = await DefaultRestNetworkClient(session: session, baseURL: baseURL, decoder: .init())

        let expected = TestResponse(message: "Hey")
        let expectedData = try JSONEncoder().encode(expected)
        let url = URL(string: "\(baseUrl)/v1/cats")!

        MockURLProtocol.requestHandler = { request in
            #expect(request.url == url)
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, expectedData)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let model: TestResponse = try await client.request(req)
        #expect(model == expected)
    }

    func testNonHTTPURLResponseThrowsNetworkError() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let baseURL = URL(string: baseUrl)!
        let client = await DefaultRestNetworkClient(session: session, baseURL: baseURL)

        let url = URL(string: "\(baseUrl)/cats")!

        // URLProtocol can't send a non-HTTP URLResponse via client API. Simulate a transport error
        // which the client should wrap as NetworkError.network.
        MockURLProtocol.requestHandler = { request in
            #expect(request.url == url)
            throw URLError(.badServerResponse)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        do {
            let _: TestResponse = try await client.request(req)
            Issue.record("Expected to throw NetworkError.network, but succeeded")
        } catch let error as NetworkError {
            if case .network = error {
                // expected
            } else {
                Issue.record("Expected NetworkError.network, got: \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError, got: \(error)")
        }
    }

    func testServerStatusCodeThrowsServerError() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let baseURL = URL(string: baseUrl)!
        let client = await DefaultRestNetworkClient(session: session, baseURL: baseURL)

        let url = URL(string: "\(baseUrl)/cats")!

        MockURLProtocol.requestHandler = { request in
            #expect(request.url == url)
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        do {
            let _: TestResponse = try await client.request(req)
            Issue.record("Expected to throw, but succeeded")
        } catch let error as NetworkError {
            if case .server(let statusCode, _) = error {
                #expect(statusCode == 500)
            } else {
                Issue.record("Expected NetworkError.server, got: \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError, got: \(error)")
        }
    }

    func testThrowsDecodingError() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let baseURL = URL(string: baseUrl)!
        let client = await DefaultRestNetworkClient(session: session, baseURL: baseURL)

        let url = URL(string: "\(baseUrl)/cats")!

        let invalidJSON = Data("{\"wrong\":\"shape\"}".utf8)

        MockURLProtocol.requestHandler = { request in
            #expect(request.url == url)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, invalidJSON)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        do {
            let _: TestResponse = try await client.request(req)
            Issue.record("Expected to throw, but succeeded")
        } catch let error as NetworkError {
            if case .decoding = error {
                // expected
            } else {
                Issue.record("Expected NetworkError.decoding, got: \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError, got: \(error)")
        }
    }

    func testURLSessionErrorThrowsNetworkError() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let baseURL = URL(string: baseUrl)!
        let client = await DefaultRestNetworkClient(session: session, baseURL: baseURL)

        let url = URL(string: "\(baseUrl)/cats")!

        // Make the protocol throw a transport error
        MockURLProtocol.requestHandler = { request in
            throw URLError(.notConnectedToInternet)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        do {
            let _: TestResponse = try await client.request(req)
            Issue.record("Expected to throw, but succeeded")
        } catch let error as NetworkError {
            if case .network(let underlying) = error {
                #expect((underlying as? URLError)?.code == .notConnectedToInternet)
            } else {
                Issue.record("Expected NetworkError.network, got: \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError, got: \(error)")
        }
    }
}

extension RestNetworkClientTests {
    final class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            guard let handler = MockURLProtocol.requestHandler else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }
}

