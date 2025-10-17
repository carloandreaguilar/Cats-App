//
//  NetworkError.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case network(underlying: Error)
    case server(statusCode: Int, message: String?)
    case decoding(underlying: Error)
}
