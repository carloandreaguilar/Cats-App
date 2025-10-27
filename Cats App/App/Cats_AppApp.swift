//
//  Cats_AppApp.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI
import SwiftData

@main
struct Cats_AppApp: App {
    private let dependencies: AppDependencies = DefaultAppDependencies()
    
    init() {
        URLCache.shared = dependencies.urlCache
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(dependencies.modelContainer)
        .environment(\.appDependencies, dependencies)
    }
}
