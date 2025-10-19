//
//  AppConstants.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 18/10/25.
//

import Foundation

enum AppConstants {
    static let defaultBaseURL = URL(string: "https://api.thecatapi.com/v1")!
    static let defaultApiKey = "live_7RYf9Kx3GFcrGzFd6UVh9yGHAbgIrivdcn9ZaI6aaKXq53jLvS1CUaReccSqNHgs"
    static let defaultPageSize = 12
    
    enum View {
        static let scrollViewFooterHeight: CGFloat = 40
    }
}
