//
//  MockBreedsNetworkService.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 21/10/25.
//

import Foundation
import SwiftData
@testable import Cats_App

final class MockBreedsNetworkService: BreedsNetworkService {
    var searchBreedsCalled = false
    var fetchBreedsCalled = false
    var shouldThrowError = false
    var allBreeds: [CatBreedDTO] = []
    
    func fetchBreeds(page: Int, pageSize: Int) async throws -> [CatBreedDTO] {
        fetchBreedsCalled = true
        if shouldThrowError { throw NetworkError.network(underlying: URLError(.notConnectedToInternet)) }
        let start = max((page - 1) * pageSize, 0)
        let end = min(start + pageSize, allBreeds.count)
        return Array(allBreeds[start..<end])
    }
    
    func searchBreeds(matching query: String, page: Int, pageSize: Int) async throws -> [CatBreedDTO] {
        searchBreedsCalled = true
        if shouldThrowError { throw NetworkError.network(underlying: URLError(.notConnectedToInternet)) }
        let start = max((page - 1) * pageSize, 0)
        let end = min(start + pageSize, allBreeds.count)
        return Array(allBreeds[start..<end])
    }
}
